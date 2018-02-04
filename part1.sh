#!/usr/bin/env bash

source common.sh

start_session

containers="client router server"
ips="192.168.100.1 192.168.100.2 192.168.101.2"

echo Testing ssh and curl
for c in $containers; do
  for ip in $ips; do
    # TODO: Stop containers querying themselves

    echo Testing $c can curl $ip
    RESPONSE=$(
      container_run $c "curl ${ip}" | tr -d '[:space:]')
    if [ "$RESPONSE" != "Hello,world!" ]; then
      echo Couldn not get page as $c from $ip
      exit
    fi

    echo Testing $c can ssh into $ip
    RESPONSE=$(
      container_run $c \
        "$sshq $ip printf '%s' success")
    if [ "$RESPONSE" != "success" ]; then
      echo Could not ssh from $c to "$ip"
    fi
  done
done

echo Success

end_session

