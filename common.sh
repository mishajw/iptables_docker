#!/usr/bin/env bash

function start_session {
  set -e

  echo Bringing up containers
  docker-compose up --build --force-recreate -d

  echo Containers running:
  docker ps -a

  # TODO: Find a deterministic method of doing this
  echo Wait for containers to go up
  sleep 2

  containers="client router server"
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

