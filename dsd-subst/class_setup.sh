# This needs some work.
# At present, it just allows you to tack classes onto the front of the current
# class list -- I feel that there is probably a need to allow the new classes
# to be added at the start of the list, just before or after the one that
# depended on them, or at the end of the list, but until I see examples
# where that extra complication is actually required, lets just do this
#
# BTW this uses the perhaps dodgy trick of relying on being run by something
# that provides the function preseed_fetch, to grab the subclass files
#

set -x

split_semi() {
  echo "$1" | sed -e 's/;/\n/g'
}

join_semi() {
  tr '\n' ';' | sed -e 's/;$//'
}

subclasses() {
   preseed_fetch "$(dirname $last_location)/${1}/subclasses" /tmp/cls-$1 || return 0
   join_semi < /tmp/cls-$1
   rm /tmp/cls-$1
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
  sieve | grep -v $x
}

classes="domain-$(debconf-get netcfg/get_domain);$(debconf-get local/classes)"

echo local local/classes string $(expandclasses "$classes" | sieve | join_semi)
