#!/usr/bin/env bash

set -e

echo Bringing up containers
docker-compose up -d

echo Containers running:
docker ps -a

# TODO: Find a deterministic method of doing this
echo Wait for containers to go up
sleep 2

containers="client router server"

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
    echo Got $RESPONSE
  done
done


echo Bringing down containers
docker-compose down

