#!/bin/sh

# This script is executed on boot to implement system
# changes for the KNL systems.  
#
# Do not directly modify this file.

chmod 666 /sys/class/powercap/intel-rapl:0/*power_limit_uw \
	/sys/class/powercap/intel-rapl:0:0/constraint_0_power_limit_uw \
	/sys/class/powercap/intel-rapl:0:0/constraint_0_time_window_us
echo 0 >  /proc/sys/vm/nr_hugepages


