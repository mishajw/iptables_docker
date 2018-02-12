#!/usr/bin/env bash

# TODO: This relies on docker setting up `server_net` on `eth1` for router
CLIENT_IFACE=eth0
SERVER_IFACE=eth1

# Block all traffic coming from `server_net` that isn't from 192.168.101.0/24
iptables --append FORWARD \
    --in-interface $SERVER_IFACE \
    ! --source 192.168.101.0/24 \
    --jump DROP

# Block all traffic to `server_net` that is:
#  - Broadcast (addressed to 192.168.101.255
#  - 10.0.0.0/8
#  - 172.16.0.0/12
#  - 192.168.0.0/16
#     - Apart from 192.168.{100,101}.0/24

# Handle broadcast rule
iptables --append FORWARD \
  --destination 192.168.100.255,192.168.101.255 \
  --m pkttype \
  --pkt-type broadcast \
  --jump DROP
# Add this rule first so we accept connections from 192.168.{100,101}.0/24
iptables --append FORWARD \
  --in-interface $CLIENT_IFACE \
  --out-interface $SERVER_IFACE \
  --source 192.168.100.0/24,192.168.101.0/24 \
  --jump ACCEPT
# Block local addresses otherwise
iptables --append FORWARD \
  --in-interface $CLIENT_IFACE \
  --out-interface $SERVER_IFACE \
  --source 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 \
  --jump DROP

