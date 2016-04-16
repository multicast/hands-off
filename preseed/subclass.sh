#!/bin/sh
# subclass.sh preseed from http://hands.com/d-i/.../subclass.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

. /tmp/HandsOff-fn.sh

# === recursive class subclass processing
# At present, this just allows you to tack classes onto the front of the
# current class list
# I feel that there is probably a need to allow the new classes
# to be added at the start of the list, just before or after the one that
# depended on them, or at the end of the list, but until I see examples
# where that extra complication is actually required, lets just do this
#

db_get auto-install/classes && classes=$RET
classes="$(expandclasses "$(subclasses "");$classes" | sieve | join_semi)"

# now that we've worked out the class list, store it for later use
# if no classes were previously defined, we'll have to register the question
if ! db_set auto-install/classes "$classes"; then
	db_register hands-off/meta/string auto-install/classes
	db_set auto-install/classes "$classes"
fi

# generate class preseed inclusion list
use_local && includelcl="local/preseed "
for cls in $(split_semi $classes) ; do
  if expr "$cls" : local/ >/dev/null; then
    includelcl="$includelcl /${cls}/preseed"
  else
    include="${include}classes/${cls}/preseed "
    use_local && includelcl="${includelcl}local/${cls}/preseed "
  fi
done
# ... and get it included next

db_set preseed/include "$include$includelcl"
