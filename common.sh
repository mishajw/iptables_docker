#!/usr/bin/env bash

NUM_ATTEMPTS=10

function start_session {
  set -e

  echo Bringing up containers
  docker-compose up --build --force-recreate -d

  echo Containers running:
  docker ps -a

  # TODO: Find a deterministic method of doing this
  echo Wait for containers to go up
  sleep 2
}

function end_session {
  echo Bringing down containers
  docker-compose down
}

function container_run {
  CONTAINER_NAME=$1
  RUN_COMMAND=$2

  docker exec -it iptablesdocker_${CONTAINER_NAME}_1 \
    $RUN_COMMAND
}

function container_run_file {
  CONTAINER_NAME=$1
  FILE_NAME=$2

  docker exec -i iptablesdocker_${CONTAINER_NAME}_1 sh < $FILE_NAME
}

sshq="ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=1"

function check_client_ssh_server {
  echo Checking client can ssh to server
  RESPONSE=$(container_run client "$sshq 192.168.101.2 echo -n success")
  if [ "$RESPONSE" != "success" ]; then
    echo Failed to ssh from client to server
    exit
  fi
}

function check_client_not_curl_server {
  echo Checking client can not curl server
  RESPONSE=$(! container_run client "curl 192.168.101.2 --connect-timeout 1")
  # Checks if curl response contains 28, the error code for timeout
  # TODO: Check error code returned instead of searching string
  if [[ "$RESPONSE" != *"28"* ]]; then
    echo Client could still curl from server
    exit
  fi
}

function check_client_not_non_ssh_server {
  echo Checking client can not connect to non-ssh server ports
  for _ in `seq $NUM_ATTEMPTS`; do
    # Pick a random port not equal to 22
    PORT=$(($RANDOM % 65534 + 1))
    if [ "$PORT" = "22" ]; then
      continue
    fi

    echo Trying port $PORT
    RESPONSE=$(! container_run client "nc -w 1 192.168.101.2 ${PORT}")
    if [[ ! -z $RESPONSE ]]; then
      echo Got response from random port $PORT that should be blocked
      exit
    fi
  done
}

