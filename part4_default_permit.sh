#!/usr/bin/env bash

iptables --append FORWARD \
  --protocol tcp \
  -s 192.168.100.2 \
  -d 192.168.101.2 \
  --destination-port 80 \
  -j DROP

