#!/usr/bin/env bash

NUM_ATTEMPTS=10

source common.sh

start_session

echo Setting up server iptables rule
container_run server \
  "iptables --append INPUT --protocol tcp ! --destination-port 22 -j DROP"

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

echo Success

end_session

