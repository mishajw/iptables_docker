#!/usr/bin/env bash

source common.sh

start_session

echo Blocking all traffic from server to client on port 80 on server
container_run router " \
  iptables --append FORWARD \
    --protocol tcp \
    -s 192.168.100.2 \
    -d 192.168.101.2 \
    --destination-port 80 \
    -j DROP"

check_client_ssh_server
check_client_not_curl_server
echo Success

end_session

