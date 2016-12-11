#!/bin/sh
set -e

# avoid stray output being interpreted as preseed settings
exec 1>&2

. /usr/share/debconf/confmodule

set -x

# create templates for use in on-the-fly creation of dialogs
cat > /tmp/HandsOff.templates <<'!EOF!'
Template: pkgsel/simplified-tasksel
Type: select
Choices-C: desktop, server, custom
Choices: standard ("${DESKTOP}") desktop, standard server - installs ssh server, other use cases
Description: Choose type of system to install
 You can now choose between installing a standard desktop, a standard
 server, or alternatively to use the task selection menu to have finer
 grained control over installing tasks and blends.
!EOF!

debconf-loadtemplate pkgsel /tmp/HandsOff.templates

preseed_fetch pkgsel.postinst /tmp/pkgsel.postinst
chmod +x /tmp/pkgsel.postinst

preseed_fetch kludge.sh /tmp/kludge.sh
# drop this in the background so that it can wait for files to edit
sh /tmp/kludge.sh </dev/null >/dev/null 2>/dev/null &
