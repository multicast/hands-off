#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

# create templates for use in on-the-fly creation of dialogs
cat > /tmp/HandsOff.templates <<'!EOF!'
Template: hands-off/meta/text
Type: text
Description: ${DESC}
 ${DESCRIPTION}

Template: hands-off/meta/string
Type: string
Description: ${DESC}
 ${DESCRIPTION}

Template: hands-off/meta/boolean
Type: boolean
Description: ${DESC}
 ${DESCRIPTION}
!EOF!

debconf-loadtemplate hands-off /tmp/HandsOff.templates

cat > /tmp/HandsOff-fn.sh <<'!EOF!'
# useful functions for preseeding
in_class() {
	echo ";$(debconf-get auto-install/classes);" | grep -q ";$1;"
}
classes() {
	echo "$(debconf-get auto-install/classes)" | sed -e 's/;/\n/g'
}
checkflag() {
	flagname=$1 ; shift
	if db_get $flagname && [ "$RET" ]
	then
		for i in "$@"; do
			echo ";$RET;" | grep -q ";$i;" && return 0
		done
	fi
	return 1
}
pause() {
	desc=$1 ; shift

	db_register hands-off/meta/text hands-off/pause/title
	db_subst hands-off/pause/title DESC "Conditional Debugging Pause"
	db_settitle hands-off/pause/title

	db_register hands-off/meta/text hands-off/pause
	db_subst hands-off/pause DESCRIPTION "$desc"
	db_input critical hands-off/pause
	db_unregister hands-off/pause
	db_unregister hands-off/pause/title
	db_go
}

# db_set fails if the variable is not already registered -- this gets round that
# this might need to check if the variable already exits
db_really_set() {
  var=$1 ; shift
  val=$1 ; shift
  seen=$1 ; shift

  db_register debian-installer/dummy "$var"
  db_set "$var" "$val"
  db_subst "$var" ID "$var"
  db_fset "$var" seen "$seen"
}

check_udeb_ver() {
        # returns true if the udeb is at least Version: ver
	udeb=$1 ; shift
        ver=$1 ; shift

        { echo $ver ;
          sed -ne '/^Package: '${udeb}'$/,/^$/s/^Version: \(.*\)$/\1/p' /var/lib/dpkg/status ;
        } | sort -t. -c 2>/dev/null
}
!EOF!

. /usr/share/debconf/confmodule
. /tmp/HandsOff-fn.sh

checkflag dbg/pauses all start && pause "Top Level start.sh script"

check_udeb_ver preseed-common 1.29 || backcompat=etch.sh

preseed_fetch local_enabled_flag /tmp/local_enabled_flag
use_local=$(grep -v '^[[:space:]]*\(#\|$\)' /tmp/local_enabled_flag || true)
rm /tmp/local_enabled_flag
echo $use_local > /var/run/hands-off.local
if [ "true" = "$use_local" ]
then
  db_set preseed/run local/start.sh subclass.sh $backcompat
else
  db_set preseed/run subclass.sh $backcompat
fi

# Make sure that auto-install/classes exists, even if it wasn't on the cmdline
db_get auto-install/classes || {
  db_register hands-off/meta/string auto-install/classes/title
  db_register hands-off/meta/string auto-install/classes
  db_subst auto-install/classes ID auto-install/classes
}

if [ -z "$(debconf-get auto-install/classes)" -a \
     -e /var/run/preseed_unspecified_at_boot  -o \
     -e /var/run/auto-install-had-to-ask-for-preseed ]; then
  db_subst auto-install/classes/title DESC "Which auto-install classes do you want to set?"
  db_settitle auto-install/classes/title

  db_subst auto-install/classes DESCRIPTION "\
Here you can specify a list of classes you wish to set for this install.  Classes should be separated by semi-colons(;), thus:

  desktop;loc/gb

If you set it to 'tutorial' you'll be given a short tutorial on automated installation.

Leave this blank for a minimal default install:"
  db_set auto-install/classes tutorial
  db_input critical auto-install/classes
  db_go
fi
