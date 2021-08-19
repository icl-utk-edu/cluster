#!/bin/sh
yum --enablerepo=rocm clean expire-cache
yum --enablerepo=rocm clean all
yum --enablerepo=rocm install rocm-dkms roctracer-dev hipblas rocblas hipsparse hip-nvcc rocsparse rocprim aomp-amdgpu rocsolver
