#!/bin/bash -e

VARIANT=$1

if [[ $VARIANT = 'kernel3' ]]; then
   KVER=3.10.0-1160.102.1.el7.x86_64
   source /tmp/spack/share/spack/setup-env.sh
   spack load gcc
   dnf --disablerepo=* --enablerepo=centos7,centos7-updates,epel7 install \
   dkms kernel-$KVER kernel-devel-$KVER
fi
if [[ $VARIANT = 'kernel4' ]]; then
   KVER=4.18.0-477.10.1.el8_8.x86_64
   dnf -y --disablerepo=* --enablerepo=RL8,epel8 install \
	   dkms kernel-$KVER kernel-core-$KVER kernel-devel-$KVER kernel-modules-$KVER
fi
if [[ $VARIANT = 'kernel66' ]]; then
   KVER=6.6.1-1.el9.elrepo.x86_64
   dnf -y --enablerepo=elrepo-kernel-archive install kernel-ml-$KVER kernel-ml-devel-$KVER
fi
if [[ $VARIANT = 'kernel-stock' ]]; then
   dnf -y install kernel kernel-devel
   KVER=`rpm -q kernel | sed 's/kernel-//'`
fi
if [[ $VARIANT = 'base' ]]; then
   KVER=6.1.81-1.el9.elrepo.x86_64
   dnf -y --enablerepo=elrepo-kernel-archive install kernel-lt-$KVER kernel-lt-devel-$KVER
fi

echo $KVER > /boot/kver

