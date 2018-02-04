#!/usr/bin/env bash

source common.sh

start_session

echo Blocking all traffic but client to server on port 22 on router
container_run_file router part4.sh

check_client_ssh_server
check_client_not_curl_server
echo Success

end_session

