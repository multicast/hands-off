#!/bin/sh

f=/var/lib/dpkg/info/pkgsel.postinst
# replace pkgsel's postinst before it gets invoked
while [ ! -e $f ] ; do
	sleep 1
done

mv -f /tmp/pkgsel.postinst $f

# put some debugging into the tasksel's debconf helper
f=/target/usr/lib/tasksel/tasksel-debconf
while [ ! -e $f ] ; do
        sleep 1
done

sed -i '/^db_go/a echo "[DEBUG-846002]: continuing after db_go -- if you get to here after having pressed [BACK] then db_go did not return 30 as it should -- which is a bug AFAICS" >&2' $f
