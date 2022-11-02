#!/bin/sh

# This script is executed on boot to implement system
# changes for PAPI development.  
#
# Do not directly modify this file.

chmod 666 /sys/class/powercap/intel-rapl*/*power_limit_uw \
	/sys/class/powercap/intel-rapl*/constraint_*_power_limit_uw \
	/sys/class/powercap/intel-rapl*/constraint_*_time_window_us

#echo 0 >  /proc/sys/vm/nr_hugepages

chown root.papi /dev/cpu/*/msr
chmod 740 /dev/cpu/*/msr

