#!/bin/sh
set -e

# avoid stray output being interpreted as preseed settings
exec 1>&2

. /usr/share/debconf/confmodule

set -x

preseed_fetch resize.sh /tmp/resize.sh
chmod +x /tmp/resize.sh

preseed_fetch kludge.sh /tmp/kludge.sh
# drop this in the background so that it can wait for files to edit
sh /tmp/kludge.sh </dev/null >/dev/null 2>/dev/null &
