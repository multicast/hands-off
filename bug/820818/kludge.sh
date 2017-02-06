#!/bin/sh

f=/lib/partman/lib/resize.sh
# replace pkgsel's postinst before it gets invoked
while [ ! -e $f ] ; do
	sleep 1
done

mv -f /tmp/$(basename $f) $f
