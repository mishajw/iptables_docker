#!/usr/bin/env bash

source common.sh

start_session

echo Blocking all ports but 22 on server
container_run_file server part3.sh

check_client_ssh_server
check_client_not_non_ssh_server
echo Success

end_session

