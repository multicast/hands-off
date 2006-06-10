#!/bin/sh
# 0-check-local.sh preseed from http://hands.com/d-i/dsd/0-check-local.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#

. /usr/share/dashslashdash/functions.sh

if db_get dsd/use_local && [ true = "$RET" ]
then
  db_set preseed/run ../local/0-early-dsd-setup.sh 0-early-dsd-setup.sh
else
  db_set preseed/run 0-early-dsd-setup.sh
fi
