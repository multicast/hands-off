#!/bin/sh

postinst=/var/lib/dpkg/info/pkgsel.postinst
# this is a joyous race condition
while [ ! -e $postinst ] ; do
	sleep 1
done

mv -f /tmp/pkgsel.postinst $postinst
