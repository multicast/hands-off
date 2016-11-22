#!/bin/sh
# etch.sh preseed from http://hands.com/d-i/.../etch.sh
#
# Copyright (c) 2008 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

. /tmp/HandsOff-fn.sh

checkflag dbg/pauses all etch && pause "Top Level etch.sh script 1"

# Etch was more verbose here
if db_get mirror/country && [ "manual" = "$RET" ] ; then
  db_set mirror/country "enter information manually"
fi

# in Lenny you leave this unset, although that breaks on multi-disk systems
if ! db_get partman-auto/disk || [ -z "$RET" ] ; then
  db_really_set partman-auto/disk /dev/discs/disc0/disc true
fi
