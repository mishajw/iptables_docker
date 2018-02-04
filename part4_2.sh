#!/usr/bin/env bash

source common.sh

start_session

echo Blocking all traffic but client to server on port 22 on server
# Set the default forward operation to drop
container_run router "iptables -P FORWARD DROP"
# Allow packets that go from client to server on port 80
container_run router " \
  iptables --append FORWARD \
    --protocol tcp \
    --destination-port 22 \
    -j ACCEPT"
# Also allow packets that are part of a session that has already
# been accpeted, or related to it
container_run router " \
  iptables --append FORWARD \
    --protocol tcp \
    --match state \
    --state ESTABLISHED,RELATED \
    -j ACCEPT"

# # This blocks all connections between client and server apart
# # from 22, but does not affect other machines
# container_run router " \
#   iptables --append FORWARD \
#     --protocol tcp \
#     -s 192.168.100.2 \
#     -d 192.168.101.2 \
#     ! --destination-port 22 -j DROP"

check_client_ssh_server
check_client_not_curl_server
echo Success

end_session

