#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

. /usr/share/debconf/confmodule

preseed_fetch local_enabled_flag /tmp/local_enabled_flag
use_local=$(grep -v '^[[:space:]]*\(#\|$\)' /tmp/local_enabled_flag)
rm /tmp/local_enabled_flag
echo $use_local > /var/run/hands-off.local
if [ "true" = "$use_local" ]
then
  db_set preseed/run local/start.sh subclass.sh
else
  db_set preseed/run subclass.sh
fi

cat > /tmp/HandsOff-fn.sh <<'!EOF!'
# useful functions for preseeding
in_class() {
    echo ";$(debconf-get auto-install/classes);" | grep -q ";$1;"
}
classes() {
    echo "$(debconf-get auto-install/classes)" | sed -e 's/;/\n/g'
}
dbg_pause() {
desc=$1 ; shift

if [ "$*" ]; then
  match=false
  for i in $@; do
    echo ";$(debconf-get dbg/pauses);" | grep -q ";$1;" && match=true
  done
  [ true = $match ] || return 0
fi

db_register preseed/meta/text hands-off/pause/title
db_subst hands-off/pause/title DESC "Conditional Debugging Pause"
db_settitle hands-off/pause/title

db_register preseed/meta/text hands-off/pause
db_subst hands-off/pause DESCRIPTION "$desc"
db_input critical hands-off/pause
db_unregister hands-off/pause
db_unregister hands-off/pause/title
}
!EOF!
