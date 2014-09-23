#!/bin/sh

wait_for() {
  test -e $1 && return 0

  echo -n Waiting for $1 ...
  while ! test -e $1 ; do
    sleep 1
    echo -n .
  done
  echo
}

add_x() {
  wait_for $1
  # get some debug output
  echo -n "add_xv $1 ..."
  sed -i -e "1a\exec 2>/tmp/debug-$(basename $1).\$\$ \; set -x" $1
  echo " done."
}

# this lets you add a pause to a script -- you can tell the PID from the duration
add_sleep() {
  wait_for $1
  # get some debug output
  echo -n "add_sleep $1 ..."
  sed -i -e "1a\sleep \$((100000 + \$\$)) || true" $1
  echo " done."
}

add_sleep_fn() {
  wait_for $1
  # get some debug output
  echo -n "add_sleep_fn $1 $2 ..."
  sed -i -e "/$2() {/a\sleep \$((100000 + \$\$)) || true" $1
  echo " done."
}

top_and_tail() {
  echo -n "top_and_tail $1 ..."
  wait_for $1
  sed -ie 's#\(.*\)() *{#\0\n  echo "START:\1 \$@">\&2\n  REAL_\1 \"$@\"\n  RETVAL=$?\n  echo "END:\1 \$@">\&2;\n  return $RETVAL\n}\nREAL_\0#' $1
  echo " done."
}
