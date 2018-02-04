#!/usr/bin/env bash

source common.sh

start_session

echo Blocking all ports but 22 on server
container_run server \
  "iptables --append INPUT --protocol tcp ! --destination-port 22 -j DROP"

check_client_ssh_server
check_client_not_non_ssh_server
echo Success

end_session

