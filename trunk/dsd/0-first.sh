#!/bin/sh
# 0-first.sh preseed from http://hands.com/d-i/dsd/0-first.cfg
#
# Copyright (c) 2005 Hands.com Ltd
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
#
# It is likely, that with the advent of the new dashslashdash substitution
# aproach, with executable preseed scripts, I'll be able to reduce the nummber
# of seprate config files, but for the moment, I'll leave it pretty much as
# it is apart from making this one executable for later flexibility
#

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

d-i preseed/include     string class_setup.sh|

# This line is currently only including second.cfg -- I'm hoping to work out
# something interesting to allow for more flexible subclassing using the
# subclass.sh files -- this needs some inspiration first
d-i preseed/include_command     string echo second.cfg

### previous try ...
#d-i preseed/include_command     string ( echo "domain-$(debconf-get netcfg/get_domain)/subclass.sh|?"; IFS=';'; for cls in $(debconf-get dsd/classes); do [ "$cls" ] && echo "${cls}/subclass.sh|?"; done ; echo second.cfg )
!EOF!
