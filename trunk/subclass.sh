#!/bin/sh
# subclass.sh preseed from http://hands.com/d-i/.../subclass.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#

. /usr/share/debconf/confmodule

# === recursive class subclass processing
# At present, this just allows you to tack classes onto the front of the
# current class list
# I feel that there is probably a need to allow the new classes
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
   if [ -n "$class" ] && ! expr "$class" : local/ >/dev/null  ; then
     preseed_fetch "/classes/$class/subclasses" /tmp/cls-$cl_a_ss || return 0
   fi
   preseed_fetch "/local/$class/subclasses" /tmp/cls-$cl_a_ss-local
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

db_get auto-install/classes && classes=$RET
classes="$(expandclasses "$(subclasses "");$classes" | sieve | join_semi)"

# now that we've worked out the class list, store it for later use
# if no classes were previously defined, we'll have to register the question
if ! db_set auto-install/classes "$classes"; then
	db_register preseed/meta/string auto-install/classes
	db_set auto-install/classes "$classes"
fi

db_get local/use_local_directory && use_local=true
[ "true" = "$use_local" ] && includelcl="local/preseed"

# generate class preseed inclusion list
for cls in $(split_semi $classes) ; do
  expr "$class" : local/ >/dev/null || include="${include}classes/${cls}/preseed "
  [ "true" = "$use_local" ] && includelcl="$includelcl local/${cls}/preseed"
done
# ... and get it included next

db_set preseed/include "$include$includelcl"
