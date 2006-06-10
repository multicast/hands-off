#!/bin/sh
# local/0-early-dsd-setup.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#

. /usr/share/dashslashdash/functions.sh

if db_get -/host
then
  dsd_host="$RET"
  dsd_name="$(expr "$dsd_host" : "\([^:.]*\)")"
  dsd_domain="$(expr "$dsd_host" : "[^:.]*\.\([^:]*\)")"
fi

# example of using a machine name pattern to select extra class(es), and so
# save some typing at the boot prompt
case "$dsd_name" in
  spdxfw*)
    if db_get dsd/classes && [ -n "$RET" ]
    then
      db_set dsd/classes "spdx/firewall;$RET"
    else
      db_set dsd/classes "spdx/firewall"
    fi
    ;;
esac
