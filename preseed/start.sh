#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# Copyright © 2012-2016 Daniel Dehennin <daniel.dehennin@baby-gnu.org>
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

# Download HandsOff utilities
preseed_fetch utils/HandsOff-fn.sh /tmp/HandsOff-fn.sh

. /tmp/HandsOff-fn.sh

checkflag dbg/pauses all start && pause "Top Level start.sh script"
checkflag dbg/flags all-x start-x && set -x

check_udeb_ver preseed-common 1.29 || backcompat=etch.sh

preseed_fetch local_enabled_flag /tmp/local_enabled_flag
use_local=$(grep -v '^[[:space:]]*\(#\|$\)' /tmp/local_enabled_flag || true)
rm /tmp/local_enabled_flag
echo $use_local > /var/run/hands-off.local

if use_local && preseed_fetch local/start.sh /tmp/local_start.sh
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

# kludge to deal with breakage in Jessie
if [ -e /var/run/preseed_unspecified_at_boot ] &&
   grep -q '{ db_get preseed/url  || \[ -z "$RET" \]; } &&' /lib/debian-installer-startup.d/S60auto-install
then
  echo "removing /var/run/preseed_unspecified_at_boot, which is probably spurious"
  rm /var/run/preseed_unspecified_at_boot || true
fi

if [ -z "$(debconf-get auto-install/classes)" -o \
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
