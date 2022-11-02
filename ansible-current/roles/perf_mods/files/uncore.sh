#!/bin/sh

# This script is executed on boot to implement system
# changes for the system.  
#
# Do not directly modify this file.

echo -1 > /proc/sys/kernel/perf_event_paranoid

if [ -e /proc/sys/kernel/numa_balancing ]; then
  echo 0 > /proc/sys/kernel/numa_balancing
fi


