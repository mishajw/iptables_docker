#!/usr/bin/env bash

source common.sh

start_session

for c1 in $containers; do
  for c2 in $containers; do
    if [ "$c1" = "$c2" ]; then
      continue
    fi

    echo Getting page from $c2 by $c1
    RESPONSE=$(
      docker exec -it iptablesdocker_${c1}_1 \
        wget ${c2}:8000 -q -O -
    )
    # Remove whitespace
    RESPONSE=$(echo "$RESPONSE" | tr -d '[:space:]')

    if [ "$RESPONSE" = "Hello,world!" ]; then
      echo Succeeded
    else
      exit
    fi
  done
done

end_session

