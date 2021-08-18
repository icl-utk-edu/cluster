#!/bin/sh

timeout 10 /usr/bin/ipmitool -I lanplus -H $1 -U USERID -P PASSW0RD lan set 1 ipsrc dhcp

