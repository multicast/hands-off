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
[ "true" = "$use_local" ] && includelcl="local/preseed "
for cls in $(split_semi $classes) ; do
  preseedpath="/${cls}/preseed"
  if expr "$cls" : local/ >/dev/null; then
    includelcl="$includelcl $preseedpath"
    if am_checksumming ; then
      checsums_lcl="$checsums_lcl $(/bin/preseed_lookup_checksum $preseedpath)"
    fi
  else
    include="${include}classes${preseedpath} "
    if am_checksumming ; then
      checsums="$checsums$(/bin/preseed_lookup_checksum classes$preseedpath) "
    fi
    if [ "true" = "$use_local" ] ; then
      includelcl="${includelcl}local${preseedpath} "
      if am_checksumming ; then
        checsums_lcl="$checsums_lcl $(/bin/preseed_lookup_checksum local$preseedpath)"
      fi
    fi
  fi
done
# ... and get it included next

db_set preseed/include "$include$includelcl"
if am_checksumming ; then
   db_set preseed/include/checksum "$checsums$checsums_lcl"
fi
