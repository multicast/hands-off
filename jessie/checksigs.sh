#!/bin/sh
# checksigs.sh preseed from http://hands.com/d-i/.../checksigs.sh
#
# Copyright (c) 2008-2014 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

. /usr/share/debconf/confmodule

set -x

db_get hands-off/checksigs && checksigs="$RET"

if [ "true" = "$checksigs" ] ; then
	sums=/var/lib/preseed/checksums-md5sum
	lookup=/bin/preseed_lookup_checksum

	# Should be adding a checksum from a signed checksum file here
	for f in MD5SUMS.asc trustedkeys.gpg ; do
		preseed_fetch $f /tmp/$f
	done
	tmp_sums=/tmp/MD5SUMS.asc
	keys=/tmp/trustedkeys.gpg

	# let's see if this gets us past the gpgv call below (which eats entropy) -- this is a pathetic kludge, but seems to do the trick
	ping -c 100 $(ip route | sed -n '/^default via \([.0-9]*\) .*$/\1/p') > /dev/null &

	# FIXME: we need some way to bootstrap this trust, since anyone could add their key to this downloaded file
	gpgv --keyring $keys $tmp_sums || exit 1

	mv $tmp_sums $sums

	if [ ! -f $lookup ] ; then
		# if the lookup script is missing, add our own
		cat > $lookup <<-!EOF!
			#!/bin/sh -e
			grep " \$1$" $sums | cut -d\  -f1)
			!EOF!
		chmod +x $lookup
	fi

	db_set preseed/include/checksum $($lookup start.cfg)
fi
db_set preseed/include start.cfg
