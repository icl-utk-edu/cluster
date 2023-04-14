#!/bin/sh

# Need yum install dracut-network dracut-config-generic

dracut -NM --force initramfs.img
chmod 644 initramfs.img

rm -rf temp
mkdir temp
cd temp
(cpio -id; zcat | cpio -id) < ../initramfs.img

