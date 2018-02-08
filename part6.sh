#!/usr/bin/env bash

# If the limit is less than 1/sec, log it and drop it
iptables --delete-chain LOGANDDROP
iptables --new-chain LOGANDDROP
iptables --append LOGANDDROP \
  --match hashlimit \
  --hashlimit-name "LOGANDDROP" \
  --hashlimit-mode srcip,dstport \
  --hashlimit-upto 1/second \
  --hashlimit-burst 1 \
  --jump NFLOG \
  --nflog-prefix "iptables dropped packet:"
iptables --append LOGANDDROP \
  --jump DROP

# Copied from `./part4.sh`, replacing `DROP` with `LOGANDDROP`

# Allow packets that go from client to server on port 80
iptables --append FORWARD \
  --protocol tcp \
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
iptables --append FORWARD -j LOGANDDROP

