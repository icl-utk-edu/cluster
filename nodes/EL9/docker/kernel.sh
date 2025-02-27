#!/bin/bash -e

VERSION=$1

if [[ $VERSION = '3' ]]; then
   VERSION="default"
   # This kernel version is grabbed from a CentOS7 in the pxe configuration
   #  rather than being installed inside the image. The EL7 image must be built for this to work.
fi

if [[ $VERSION = '4' ]]; then
   KVER=4.18.0-477.10.1.el8_8.x86_64
   dnf -y --disablerepo=* --enablerepo=RL8,epel8 install \
	   dkms kernel-$KVER kernel-core-$KVER kernel-devel-$KVER kernel-modules-$KVER
elif [[ $VERSION = '66' ]]; then
   KVER=6.6.1-1.el9.elrepo.x86_64
   dnf -y --enablerepo=elrepo-kernel-archive install kernel-ml-$KVER kernel-ml-devel-$KVER
elif [[ $VERSION = 'default' ]]; then
   KVER=5.14.0-362.24.1.el9_3.0.1.x86_64
   dnf -y --enablerepo=vault\* install kernel-$KVER kernel-devel-matched-$KVER
   #KVER=`rpm -q kernel | sed 's/kernel-//'`
elif [[ $VERSION = '61' ]]; then
   KVER=6.1.129-1.el9.elrepo.x86_64
   dnf -y --enablerepo=elrepo-kernel-archive install kernel-lt-$KVER kernel-lt-devel-$KVER
else
   echo "Invalid kernel version specified!"
   exit 1
fi

echo $KVER > /boot/kver
