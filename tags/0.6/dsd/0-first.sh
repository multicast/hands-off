#!/bin/sh
# 0-first.sh preseed from http://hands.com/d-i/dsd/0-first.cfg
#
# Copyright (c) 2005-2006 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
# It is likely, that with the advent of the new dashslashdash substitution
# aproach, with executable preseed scripts, I'll be able to reduce the nummber
# of seprate config files, but for the moment, I'll leave it pretty much as
# it is apart from making this one executable for later flexibility
#

# this is a bit of a kludge -- it lets us set the host and domain back to
# what we set on the kernel command line, but only if this script is being
# run after the network came up -- this needs more work
dsd_host="$(debconf-get -/host || true)"
dsd_name="$(expr "$dsd_host" : "\([^:.]*\)")"
dsd_domain="$(expr "$dsd_host" : "[^:.]*\.\([^:]*\)")"
hostname="${dsd_name:-$(debconf-get netcfg/get_hostname || true)}"
domain="${dsd_domain:-$(debconf-get netcfg/get_domain || true)}"
cat <<!EOF!
d-i     netcfg/get_hostname          string ${hostname}
d-i     netcfg/get_domain            string ${domain}
d-i     base-config/get-hostname     string ${hostname}
!EOF!

cat <<'!EOF!'
# here we put stuff that we expect to override
d-i     languagechooser/language-name   string English
d-i     countrychooser/shortlist        string US
d-i     console-keymaps-at/keymap       string us
d-i     mirror/country                  string enter information manually
d-i     mirror/http/hostname            string ftp.debian.org
d-i     mirror/http/directory           string /debian
base-config     apt-setup/hostname      string ftp.debian.org
base-config     apt-setup/directory     string /debian

d-i preseed/include     string _class_setup.sh|

# This line is currently only including second.cfg -- I'm hoping to work out
# something interesting to allow for more flexible subclassing using the
# subclass.sh files -- this needs some inspiration first
d-i preseed/include_command     string echo 0-second.cfg
!EOF!
