#!/usr/bin/env bash

source common.sh

start_session

echo Blocking curl on server
container_run_file server part2.sh

check_client_ssh_server
check_client_not_curl_server
echo Success

end_session

