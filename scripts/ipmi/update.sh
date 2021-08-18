#!/bin/sh

while ['' -eq '']; do
  ping -c1 -W1 10.38.80.6 && ipmitool 10.38.80.6 lan set 1 ipsrc dhcp
  sleep 10
done
