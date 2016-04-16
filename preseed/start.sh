#!/bin/sh
# start.sh preseed from http://hands.com/d-i/.../start.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# Copyright © 2012-2016 Daniel Dehennin <daniel.dehennin@baby-gnu.org>
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

. /usr/share/debconf/confmodule

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

# Make sure that auto-install/classes exists, even if it wasn't on the cmdline
db_get auto-install/classes || {
  db_register hands-off/meta/string auto-install/classes/title
  db_register hands-off/meta/string auto-install/classes
  db_subst auto-install/classes ID auto-install/classes
}

# Local classes can be set by the local_enabled_flag file
# or by hands-off/local=(true|false) command line option
preseed_fetch $CHECKSUM_IF_AVAIL local_enabled_flag /var/run/hands-off.local
if db_get hands-off/local ; then
  echo "${RET}" > /var/run/hands-off.local
fi

if use_local && preseed_fetch local/start.sh /tmp/local_start.sh ; then
  local_start=local/start.sh
fi

for i in $local_start subclass.sh $backcompat ; do
  run_scripts="$run_scripts $i"
  if am_checksumming ; then
    run_checksums="$run_checksums $(/bin/preseed_lookup_checksum $i)"
  fi
done
db_set preseed/run $run_scripts
if am_checksumming ; then
  db_set preseed/run/checksum $run_checksums
fi

# Configure /etc/nsswitch.conf to make “hostname -d” working
echo -e "\nhosts: dns files" >> /etc/nsswitch.conf

# Hostname/DNS domain are set from
# 1) DHCP
# 2) netcfg/get_hostname
if HOSTNAME=$(hostname) && [ "${HOSTNAME}" != '(none)' ] ; then
    preseed_fetch "classes/$HOSTNAME/preseed" /tmp/.test_fetch \
        && hostname_cls="$HOSTNAME"

    use_local \
	&& preseed_fetch "local/$HOSTNAME/preseed" /tmp/.test_fetch \
        && hostname_cls="${hostname_cls};local/$HOSTNAME"
fi

if DNS_DOMAIN=$(hostname -d 2> /dev/null); then
    preseed_fetch "classes/$DNS_DOMAIN/preseed" /tmp/.test_fetch \
        && domain_cls="$DNS_DOMAIN"

    use_local \
	&& preseed_fetch "local/$DNS_DOMAIN/preseed" /tmp/.test_fetch \
        && domain_cls="${domain_cls};local/$DNS_DOMAIN"
fi

if [ -n "${DNS_DOMAIN}" -a -n "${HOSTNAME}" ]; then
    preseed_fetch "classes/$DNS_DOMAIN/$HOSTNAME/preseed" /tmp/.test_fetch \
        && fqdn="$DNS_DOMAIN/$HOSTNAME"

    use_local \
	&& preseed_fetch "local/$DNS_DOMAIN/$HOSTNAME/preseed" /tmp/.test_fetch \
        && fqdn="${fqdn};local/$DNS_DOMAIN/$HOSTNAME"
fi

if [ -n "${domain_cls}" -o -n "${hostname_cls}" -o -n "${fqdn}" ]; then
    append_classes "${domain_cls};${hostname_cls};${fqdn}"
fi

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
