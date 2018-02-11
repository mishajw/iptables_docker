#!usr/bin/env bash

# Allow packets that go from client to server on port 80
iptables --append FORWARD \
  --protocol tcp \
  --source 192.168.100.2 \
  --destination 192.168.101.2 \
  --destination-port 22 \
  -j ACCEPT
# Also allow packets that are part of a session that has already
# been accpeted, or related to it
iptables --append FORWARD \
  --protocol tcp \
  --match state \
  --state ESTABLISHED,RELATED \
  -j ACCEPT

# If neither of the above rules match, drop the packet
iptables --append FORWARD -j DROP

# # This blocks all connections between client and server apart
# # from 22, but does not affect other machines
# iptables --append FORWARD \
#   --protocol tcp \
#   -s 192.168.100.2 \
#   -d 192.168.101.2 \
#   ! --destination-port 22 -j DROP

