#!/usr/bin/env bash

source common.sh

start_session

BLOCKED_IPS="10.0.0.234 172.16.0.234 192.168.0.234"

try_nmap_ips() {
  echo Trying to send packets to server from blocked IPs
  for ip in $BLOCKED_IPS; do
    echo Trying with IP $ip
    container_run client \
      "nmap
        -S $ip
        -e eth0
        --disable-arp-ping
        -sU -Pn
        -p 12345
        192.168.101.2"
  done

  # There is a delay in packets making it through to the server, so we need to
  # sleep here to make sure that they will exist when we `grep` for them
  # TODO: This delay sometimes isn't long enough - is there a way to fix this?
  sleep 10
}

log_server_packets() {
  docker exec iptablesdocker_server_1 \
    sh -c "tcpdump -nn > tcpdump.txt" &
}

echo Logging packets on server
log_server_packets
LOG_PACKETS_JOB=$!

try_nmap_ips

echo Checking that blocked IPs do appear in logs
for ip in $BLOCKED_IPS; do
  grep "$ip" <(container_run server "cat tcpdump.txt")
done

echo Restarting logging packets on server
kill $LOG_PACKETS_JOB
log_server_packets

echo Blocking broadcast and local subnets
container_run_file router part5.sh

check_client_ssh_server

try_nmap_ips

echo Checking that blocked IPs do not appear in logs
for ip in $BLOCKED_IPS; do
  ! grep "$ip" <(container_run server "cat tcpdump.txt")
done

echo Success

end_session

