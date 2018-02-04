#!/usr/bin/env bash

iptables --append INPUT --protocol tcp ! --destination-port 22 -j DROP

