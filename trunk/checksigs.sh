#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2008 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

. /usr/share/debconf/confmodule

# Should be adding a checksum from a signed checksum file here
db_set preseed/include start.cfg

