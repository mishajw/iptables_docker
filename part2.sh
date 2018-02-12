#!/usr/bin/env bash

iptables -F

iptables --append INPUT --protocol tcp --destination-port 80 -j DROP

