#!/usr/bin/env bash

source common.sh

start_session

echo Blocking server:80
container_run server \
  "iptables --append INPUT --protocol tcp --destination-port 80 -j DROP"

echo Checking ssh from client
RESPONSE=$(container_run client "$sshq 192.168.101.2 echo -n success")
if [ "$RESPONSE" != "success" ]; then
  echo Failed to ssh from client to server
  exit
fi

# Checks if curl response contains 28, the error code for timeout
echo Checking curl from client
RESPONSE=$(! container_run client "curl 192.168.101.2 --connect-timeout 1")
if [[ "$RESPONSE" != *"28"* ]]; then
  echo Client could still curl from server
fi

echo Success

end_session

