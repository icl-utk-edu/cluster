#!/bin/sh

rpm -qa --filesbypkg | grep /opt/rocm | awk '{print $1}' | sort -u | \
   xargs -r yum -y remove
yum -y remove rock-dkms rock-dkms-firmware

#yum remove rocm-dkms roctracer-dev hipblas rocblas hipsparse hip-nvcc rocsparse rocprim aomp-amdgpu \*rocm\* rock-dkms hsakmt\* rocsolver llvm-amdgpu
