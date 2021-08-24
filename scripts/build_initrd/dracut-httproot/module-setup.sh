#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

check() {
    return 0
}

depends() {
    # We depend on network modules being loaded
    echo network
}

install() {
    inst_hook cmdline 90 "$moddir/parse-httproot.sh"
    inst "$moddir/httproot.sh" "/sbin/httproot"
    dracut_need_initqueue
}
