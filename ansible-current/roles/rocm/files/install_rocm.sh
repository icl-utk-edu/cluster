#!/bin/sh

YUM="yum --enablerepo=rocm,amdgpu -y"

$YUM clean expire-cache
$YUM clean all
$YUM install 'amdgpu-dkms' 'rocm-hip-sdk' 'rocm-dkms' 'hip-nvcc' 'rocprim' 'rocm-ml-sdk' 'rocm-openmp-sdk' 'rocm-opencl-sdk' 'rocm-developer-tools'

