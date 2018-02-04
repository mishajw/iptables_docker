#!/usr/bin/env bash

source common.sh

start_session

for c1 in $containers; do
  for c2 in $containers; do
    if [ "$c1" = "$c2" ]; then
      continue
    fi

    RESPONSE=$(
      container_run $c1 "wget ${c2} -q -O -" | tr -d '[:space:]')
    if [ "$RESPONSE" != "Hello,world!" ]; then
      echo Couldn not get page as $c1 from $c2
      exit
    fi

    RESPONSE=$(
      container_run $c1 \
        "$sshq $c2 printf '%s' success")
    if [ "$RESPONSE" != "success" ]; then
      echo Could not ssh from $c1 to $c2
    fi
  done
done

echo Success

end_session

