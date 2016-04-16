#!/bin/sh
# subclass.sh preseed from http://hands.com/d-i/.../subclass.sh
#
# Copyright (c) 2005-2006 Hands.com Ltd
# Copyright © 2012-2016 Daniel Dehennin <daniel.dehennin@baby-gnu.org>
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
set -e

. /tmp/HandsOff-fn.sh

# === recursive class subclass processing
# At present, this just allows you to tack classes onto the front of the
# current class list
# I feel that there is probably a need to allow the new classes
# to be added at the start of the list, just before or after the one that
# depended on them, or at the end of the list, but until I see examples
# where that extra complication is actually required, lets just do this
#

# Build command line classes dependencies
cmd_line_cls="$(append_classes)"

# Load all classes
load_classes "${cmd_line_cls}"
