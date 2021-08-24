#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
#. /lib/http-lib.sh

echo Begin httproot.sh >> /httplog

[ "$#" = 3 ] || exit 1

# root is in the form root=http://user:pass@[server]/[folder] either from
# cmdline or dhcp root-path
netif="$1"
root="$2"
NEWROOT="$3"

echo Mount $root at $NEWROOT >> /httplog
mount -t tmpfs tmpfs $NEWROOT
cd $NEWROOT
curl $root | tar -zx && { [ -e /dev/root ] || ln -s null /dev/root ; }


#mount.http //$server/$path $NEWROOT -o $options && { [ -e /dev/root ] || ln -s null /dev/root ; }

# inject new exit_if_exists
echo 'settle_exit_if_exists="--exit-if-exists=/dev/root"; rm -f -- "$job"' > $hookdir/initqueue/http.sh
# force udevsettle to break
> $hookdir/initqueue/work
