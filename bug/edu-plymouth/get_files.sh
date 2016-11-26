#!/bin/sh

preseed_fetch kludge.sh /tmp/kludge.sh

# drop this in the background so that it can wait for files to edit
sh /tmp/kludge.sh </dev/null >/dev/null 2>/dev/null &
