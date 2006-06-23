#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#

. /usr/share/debconf/confmodule

preseed_fetch local_is_enabled /tmp/local_is_enabled
local=$(grep -v '^#' /tmp/local_is_enabled)
db_get hands-off/local && local="$RET"

if [ "true" = "$local" ]
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
    echo ";$(debconf-get auto-install/classes);" | grep -q ";$1;"
}
classes() {
    echo "$(debconf-get auto-install/classes)" | sed -e 's/;/\n/g'
}
dbg_pause() {
desc=$1 ; shift

match=false
for i in $@; do
  echo ";$(debconf-get dbg/pauses);" | grep -q ";$1;" && match=true
done
[ true = $match ] || return 0

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
