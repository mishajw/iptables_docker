#!/usr/bin/env bash

source common.sh

start_session

echo Blocking all traffic from server to client on port 80 on router
container_run_file router part4_default_permit.sh

check_client_ssh_server
check_client_not_curl_server
echo Success

end_session

