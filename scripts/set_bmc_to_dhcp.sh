#!/bin/sh
# Find machines listening on the default Dell IPMI static address and switch then to use DHCP
# The machine that you run this from must have the corect network defined.

# Common default passwords:
#   C6100:  root calvin
#   C6145:  root root

while [ true ]; do
  ipmitool -I lanplus -H 192.168.0.120 -U root -P calvin lan print | grep 'MAC Address'
  ipmitool -I lanplus -H 192.168.0.120 -U root -P calvin lan set 1 ipsrc dhcp
  ping -c 1 192.168.0.120 >& /dev/null
  ping -c 1 -b 192.168.0.255 >& /dev/null
  sleep 10
done
