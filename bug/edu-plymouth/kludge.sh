#!/bin/sh

f=/etc/plymouth/plymouthd.conf

# this is a joyous race condition
while [ ! -e $f ] ; do
	sleep 1
done

rm -f $f
