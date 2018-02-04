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

    if [ "$RESPONSE" = "Hello,world!" ]; then
      echo Succeeded getting $c2 page from $c1
    else
      exit
    fi

    RESPONSE=$(
      container_run $c1 \
        "ssh -q -o StrictHostKeyChecking=no $c2 printf '%s' success")

    if [ "$RESPONSE" = "success" ]; then
      echo Succeeded ssh\'ing from $c1 to $c2
    else
      exit
    fi
  done
done

end_session

