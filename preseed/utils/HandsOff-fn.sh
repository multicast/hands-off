# Common utilities
#
# Copyright (c) 2005-2006 Hands.com Ltd
# Copyright © 2012-2016 Daniel Dehennin <daniel.dehennin@baby-gnu.org>
#
# Distributed under the terms of the GNU GPL version 2 or (at your
# option) any later version see the file "COPYING" for details
#
# The following utilities are usable by early and late scripts, they
# just need to source it:
#
#     . /tmp/HandsOff-fn.sh
#
. /usr/share/debconf/confmodule
. /lib/preseed/preseed.sh

# useful functions for preseeding
in_class() {
	echo ";$(debconf-get auto-install/classes);" | grep -q ";${1};"
}
classes() {
	echo "$(debconf-get auto-install/classes)" | sed 's/;/\n/g'
}
checkflag() {
	local flagname="${1}" ; shift
	if db_get "${flagname}" && [ "${RET}" ]
	then
		for i in "${@}"; do
			echo ";${RET};" | grep -q ";${i};" && return 0
		done
	fi
	return 1
}
pause() {
	local desc="${1}"

	db_register hands-off/meta/text hands-off/pause/title
	db_subst hands-off/pause/title DESC "Conditional Debugging Pause"
	db_settitle hands-off/pause/title

	db_register hands-off/meta/text hands-off/pause
	db_subst hands-off/pause DESCRIPTION "${desc}"
	db_input critical hands-off/pause
	db_unregister hands-off/pause
	db_unregister hands-off/pause/title
	db_go
}

# db_set fails if the variable is not already registered -- this gets round that
# this might need to check if the variable already exits
db_really_set() {
	local var="${1}"
	local val="${2}"
	local seen="${3}"

	db_register debian-installer/dummy "${var}"
	db_set "${var}" "${val}"
	db_subst "${var}" ID "${var}"
	db_fset "${var}" seen "${seen}"
}

# Tools
shell_escape() {
	echo $@ | sed 's/\([^-a-zA-Z0-9]\)/_/g'
}
check_udeb_ver() {
	# returns true if the udeb is at least Version: ver
	local udeb="${1}"
	local ver="${2}"

	{ echo "${ver}" ;
	  sed -ne '/^Package: '${udeb}'$/,/^$/s/^Version: \(.*\)$/\1/p' \
	      /var/lib/dpkg/status ;
	} | sort -t. -c 2>/dev/null
}

# Manipulate classes
use_local() {
	if [ -z "${handsoff_use_local}" ]
	then
		grep -qi '^true$' /var/run/hands-off.local > /dev/null 2>&1
		handsoff_use_local=$?
	fi
	[ "${handsoff_use_local}" = 0 ]
}

split_semi() {
	echo "${1}" | sed 's/;/\n/g'
}

join_semi() {
	tr '\n ' ';' | sed 's/^;\+// ; s/;\+$//; s/;;\+/;/g'
}

subclasses() {
	local class="${1}"
	local cl_a_ss=$(shell_escape "${class}")
	[ -n "${class}" ] || return 0

	if expr "${class}" : local/ >/dev/null; then
		preseed_fetch "/${class}/subclasses" \
			      "/tmp/cls-${cl_a_ss}-local" \
		    || [ $? = 4 ]
	else
		preseed_fetch "/classes/${class}/subclasses" \
			      "/tmp/cls-${cl_a_ss}" \
		    || [ $? = 4 ]

		if use_local; then
			preseed_fetch "/local/${class}/subclasses" \
			              "/tmp/cls-${cl_a_ss}-local" \
			    || [ $? = 4 ]
		fi
	fi
	for cls in "/tmp/cls-${cl_a_ss}" "/tmp/cls-${cl_a_ss}-local"; do
		[ -s "${cls}" ] || continue
		grep -v '^[[:space:]]*\(#\|$\)' "${cls}"
		rm -f "${cls}"
	done | join_semi
}

expandclasses() {
	local c
	for c in $(split_semi "${1}") ; do
		expandclasses $(subclasses "${c}")
		echo "${c}"
	done
}

sieve() {
	local x
	read x || return
	echo "${x}"
	sieve | grep -v "^${x}$"
}
