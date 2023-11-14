#!/bin/sh

FEATURE=$(hostname -s | sed -r 's/[0-9]+//g')
/usr/sbin/slurmd -D -s -Z --conf-server headnode --conf "Feature=$FEATURE"
