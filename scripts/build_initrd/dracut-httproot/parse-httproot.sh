#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# root=http://<server>/<filepath>
#

echo http start >> /httplog

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

# This script is sourced, so root should be set. But let's be paranoid
[ -z "$root" ] && root=$(getarg root=)

if [ -z "$netroot" ]; then
    echo http netroot >> /httplog
    for netroot in $(getargs netroot=); do
        [ "${netroot%%:*}" = "http" ] && break
    done
    [ "${netroot%%:*}" = "http" ] || unset netroot
fi

# Root takes precedence over netroot
if [ "${root%%:*}" = "http" ] ; then
    echo http 1 >> /httplog
    if [ -n "$netroot" ] ; then
        warn "root takes precedence over netroot. Ignoring netroot"
    fi
    netroot=$root
    unset root
fi

# If it's not http we don't continue
[ "${netroot%%:*}" = "http" ] || return

echo http end root=$root netroot=$netroot >> /httplog

# Done, all good!
rootok=1

echo '[ -e $NEWROOT/proc ]' > $hookdir/initqueue/finished/httproot.sh
