#!/bin/sh
# local/0-early-dsd-setup.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#

. /usr/share/debconf/confmodule

db_get netcfg/get_hostname &&  hostname="$RET"

case "$hostname" in
  spdxfw*)
    if db_get auto-install/classes && [ -n "$RET" ]
    then
      db_set auto-install/classes "spdx/firewall;$RET"
    else
      db_set auto-install/classes "spdx/firewall"
    fi
    ;;
esac
