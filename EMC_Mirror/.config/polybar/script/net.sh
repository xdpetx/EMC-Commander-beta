#!/bin/bash

# ping one of the root name servers
! ping -c 3 -W 2 1.1.1.1 > /dev/null 2>&1 && return
# verify connectivity
! getent hosts debian.org > /dev/null 2>&1 && return

nslookup debian.org
ip link
ip route

# Ersetze 'enp3s0' durch den Namen aus 'ip link'
#sudo ip link set enp3s0 up
#sudo dhclient enp3s0
