#!/bin/sh
# 0-first.sh preseed from http://hands.com/d-i/dsd/0-first.cfg
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
# It is likely, that with the advent of the new dashslashdash substitution
# aproach, with executable preseed scripts, I'll be able to reduce the nummber
# of seprate config files, but for the moment, I'll leave it pretty much as
# it is apart from making this one executable for later flexibility
#

. /lib/share/dashslashdash/functions.sh

# this is a bit of a kludge -- it lets us set the host and domain back to
# what we set on the kernel command line, but only if this script is being
# run after the network came up -- this needs more work
db_get -/host && dsd_host="$RET"
dsd_name="$(expr "$dsd_host" : "\([^:.]*\)")"
dsd_domain="$(expr "$dsd_host" : "[^:.]*\.\([^:]*\)")"
db_get netcfg/get_hostname || RET=ERROR-hostname-unset
hostname="${dsd_name:-$RET}"
db_get netcfg/get_domain || RET=ERROR-domain-unset
domain="${dsd_domain:-$RET}"
cat <<!EOF!
d-i     netcfg/get_hostname          string ${hostname}
d-i     netcfg/get_domain            string ${domain}
d-i     base-config/get-hostname     string ${hostname}
!EOF!

cat <<'!EOF!'
# here we put stuff that we expect to override
d-i     languagechooser/language-name   string English
d-i     countrychooser/shortlist        string US
d-i     console-keymaps-at/keymap       string us
d-i     mirror/country                  string enter information manually
d-i     mirror/http/hostname            string ftp.debian.org
d-i     mirror/http/directory           string /debian
base-config     apt-setup/hostname      string ftp.debian.org
base-config     apt-setup/directory     string /debian
!EOF!

# === recursive class subclass processing
# This needs some work.
# At present, it just allows you to tack classes onto the front of the current
# class list -- I feel that there is probably a need to allow the new classes
# to be added at the start of the list, just before or after the one that
# depended on them, or at the end of the list, but until I see examples
# where that extra complication is actually required, lets just do this
#

split_semi() {
  echo "$1" | sed -e 's/;/\n/g'
}

join_semi() {
  tr '\n' ';' | sed -e 's/;$//'
}

subclasses() {
   class=$1
   cl_a_ss=$(echo ${class}|sed 's/\([^-a-zA-Z0-9]\)/_/g')
   if [ -n "$class" ] ; then
     dsd_fetch_file "dsd/$class/subclasses" /tmp/cls-$cl_a_ss || return 0
   fi
   dsd_fetch_file "local/$class/subclasses" /tmp/cls-$cl_a_ss-local
   cat /tmp/cls-$cl_a_ss /tmp/cls-$cl_a_ss-local | join_semi
   rm /tmp/cls-$cl_a_ss /tmp/cls-$cl_a_ss-local
}

expandclasses() {
  for c in $(split_semi $1) ; do
    expandclasses $(subclasses $c)
  done
  for c in $(split_semi $1) ; do
    echo $c
  done
}

sieve() {
  read x || return
  echo $x
  sieve | grep -v "^$x$"
}

db_get dsd/classes && classes=$RET
classes="$(subclasses "");$classes"

# now that we've worked out the class list, store it for later use
echo dsd dsd/classes string $(expandclasses "$classes" | sieve | join_semi)

# generate class preseed inclusion list
for cls in $(split_semi $classes) ; do
  include="$include ${cls}/preseed"
  includelcl="$includelcl ../local/${cls}/preseed?"
done
# ... and get it included next
echo "d-i preseed/include string _common.cfg$include ../local/preseed?$includelcl"
