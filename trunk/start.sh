#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#

. /usr/share/debconf/confmodule

if db_get local/use_local_directory && [ true = "$RET" ]
then
  db_set preseed/run local/start.sh subclass.sh
else
  db_set preseed/run subclass.sh
fi

cat > /tmp/HandsOff-fn.sh <<'!EOF!'
# useful functions for preseeding
log() {
    logger -t $MYNAME "$@"
}
in_class() {
    echo "$(debconf-get auto-install/classes)" | sed -e 's/;/\n/g' | grep -q "^$1\$"
}
classes() {
    echo "$(debconf-get auto-install/classes)" | sed -e 's/;/\n/g'
}
!EOF!
