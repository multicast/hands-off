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
	# Should be adding a checksum from a signed checksum file here
	for f in MD5SUMS.asc trustedkeys.gpg ; do
		preseed_fetch $f /tmp/$f
	done
	sums=/tmp/MD5SUMS.asc
	keys=/tmp/trustedkeys.gpg

	# let's see if this gets us past the gpgv call below
	modprobe rng-core
	# FIXME: we need some way to bootstrap this trust, since anyone could add their key to this downloaded file
	gpgv --keyring $keys $sums

	mv $keys /var/lib/preseed/checksums-md5sum

	db_set preseed/include/checksum $(sed -ne '/ \.[/]start.cfg$/s/ .*//p' $sums)
fi
db_set preseed/include start.cfg
