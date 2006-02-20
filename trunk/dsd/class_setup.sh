# This needs some work.
# At present, it just allows you to tack classes onto the front of the current
# class list -- I feel that there is probably a need to allow the new classes
# to be added at the start of the list, just before or after the one that
# depended on them, or at the end of the list, but until I see examples
# where that extra complication is actually required, lets just do this
#

set -x

split_semi() {
  echo "$1" | sed -e 's/;/\n/g'
}

join_semi() {
  tr '\n' ';' | sed -e 's/;$//'
}

subclasses() {
   if [ -n "$1" ] ; then
     dsd_fetch_file "dsd/$1/subclasses" /tmp/cls-$1 || return 0
   fi
   dsd_fetch_file "local/$1/subclasses" /tmp/cls-$1-local
   cat /tmp/cls-$1 /tmp/cls-$1-local | join_semi
   rm /tmp/cls-$1 /tmp/cls-$1-local
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

classes="$(subclasses "");$(debconf-get dsd/classes)"

echo dsd dsd/classes string $(expandclasses "$classes" | sieve | join_semi)
