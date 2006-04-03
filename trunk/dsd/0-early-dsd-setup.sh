#!/bin/sh
# 0-early-dsd-setup.sh preseed from http://hands.com/d-i/dsd/0-early-dsd-setup.sh
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

. /usr/share/dashslashdash/functions.sh

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

db_set netcfg/get_hostname ${hostname}
db_set netcfg/get_domain ${domain}
db_set base-config/get-hostname ${hostname}

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
db_set dsd/classes "$(expandclasses "$classes" | sieve | join_semi)"

db_get dsd/use_local && use_local=true
[ "true" = "$use_local" ] && includelcl="../local/preseed"

# generate class preseed inclusion list
for cls in $(split_semi $classes) ; do
  include="$include${cls}/preseed "
  [ "true" = "$use_local" ] && includelcl="$includelcl ../local/${cls}/preseed"
done
# ... and get it included next
db_set preseed/include "$include$includelcl"
