#!/usr/bin/env bash

LOG_PATH="/var/log/ulogd_syslogemu.log"
LOG_CONFIG_PATH="/etc/ulogd.conf"
LOG_CONFIG_APPEND="stack=log1:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str1:IP2STR,print1:PRINTPKT,emu1:LOGEMU"

source common.sh

start_session

echo Appending line to logging config
# TODO: Try to use `container_run` command
docker exec -it iptablesdocker_router_1 \
  sh -c "sed -i 's/#$LOG_CONFIG_APPEND/$LOG_CONFIG_APPEND/' $LOG_CONFIG_PATH"

echo Starting logging daemon
(docker exec iptablesdocker_router_1 sh -c ulogd -v) &

echo Setting up part 4 rules and logging dropped packets
container_run_file router part6.sh

check_client_ssh_server
check_client_not_curl_server

echo Checking the router logged the failed curl
declare -a CHECK_LOGS=(
  "iptables dropped packet"
  "SRC=192.168.100.2"
  "DST=192.168.101.2")
for s in "${CHECK_LOGS[@]}"; do
  echo Checking for $s in log file "($LOG_PATH)"
  docker exec -ti iptablesdocker_router_1 grep "$s" $LOG_PATH
done

echo Spamming blocked messages from client to server
for _ in `seq 10`; do
  ! container_run client "curl 192.168.101.2:12345 --connect-timeout 0.001"
done

echo Checking rate limiting logs
NUM_LOGS=$(container_run router "grep -c 12345 /var/log/ulogd_syslogemu.log")
if [ "$NUM_LOGS" -ge "10" ]; then
  echo Router failed to rate limit logs
  exit
fi

echo Success

end_session

