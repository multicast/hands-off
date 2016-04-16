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
handsoff_box() {
	local type="${1}"
	local title="${2}"
	local desc="${3}"
	local user_value
	if [ -z "${type}" ]; then
		type='pause'
	fi
	if [ -z "${title}" ]; then
		title='Conditional Debugging Pause'
	fi
	if [ -z "${desc}" ]; then
		desc='Dummy description message'
	fi

	## Register dialogue box
	# Title
	db_register "hands-off/meta/${type}" "hands-off/${type}/title"
	db_subst "hands-off/${type}/title" DESC "${title}"
	db_settitle "hands-off/${type}/title"
	# Description
	db_register "hands-off/meta/${type}" "hands-off/${type}"
	db_subst "hands-off/${type}" DESCRIPTION "${desc}"
	db_input critical "hands-off/${type}"

	# Display dialog box
	db_go

	# Get user input
	db_get "hands-off/${type}"
	user_value="${RET}"

	# Clean
	db_reset "hands-off/${type}"
	db_unregister "hands-off/${type}"
	db_unregister "hands-off/${type}/title"

	# Set return value
	RET="${user_value}"
}
pause() {
	local desc="${1}"
	local title="${2}"
	if [ -z "${title}" ]; then
		title='Conditional Debugging Pause'
	fi
	handsoff_box 'pause' "${title}" "${desc}"
}
error() {
	local desc="${1}"
	local title="${2}"
	if [ -z "${title}" ]; then
		title='Conditional Error'
	fi
	handsoff_box 'error' "${title}" "${desc}"
}
bool() {
	local desc="${1}"
	local title="${2}"
	if [ -z "${title}" ]; then
		title='Conditional Boolean'
	fi
	handsoff_box 'boolean' "${title}" "${desc}"
	[ "${RET}" = "true" ]
}
string() {
	local desc="${1}"
	local title="${2}"
	if [ -z "${title}" ]; then
		title='Conditional String'
	fi
	handsoff_box 'string' "${title}" "${desc}"
	# Output value to user
	echo "${RET}"
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
handsoff_poweroff() {
	error 'The system will be powered off' 'PowerOff'
	db_really_set debian-installer/exit/poweroff true true
	exec /lib/debian-installer/exit
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

	if expr "${class}" : virtual/ >/dev/null; then
		return 0
	elif expr "${class}" : local/ >/dev/null; then
		preseed_fetch "/$class/subclasses" \
			      "/tmp/cls-${cl_a_ss}" \
		    || [ $? = 4 ]
	else
		preseed_fetch "/classes/${class}/subclasses" \
			      "/tmp/cls-${cl_a_ss}" \
		    || [ $? = 4 ]
	fi
	if [ -s "/tmp/cls-${cl_a_ss}" ]; then
		grep -v '^[[:space:]]*\(#\|$\)' "/tmp/cls-${cl_a_ss}" | join_semi
	fi
	rm -f "/tmp/cls-${cl_a_ss}"
}

expandclasses() {
	local c
	for c in $(split_semi "${1}") ; do
		expandclasses $(subclasses "${c}")
		echo "${c}"
		if use_local \
		    && ! expr "${c}" : local/ >/dev/null \
		    && preseed_fetch "local/${c}/preseed" "/tmp/.test_fetch"
		then
			expandclasses $(subclasses "local/${c}")
			echo "local/${c}"
		fi
	done
}

sieve() {
	local x
	read x || return
	echo "${x}"
	sieve | grep -v "^${x}$"
}

append_classes() {
	# Without argument:
	# - get classes from debconf, probably set by command line
	# - store all dependencies in debconf
	# With semi-colon separated classes list as argument:
	# - get only dependencies from argument
	# - store merged new dependencies with previous in debconf
	# Echo new dependencies classes:
	# - without argument: debconf classes dependencies
	# - with argument: classes list argument dependencies
	local cls="${1}"
	local new_classes
	local old_classes
	local merged_classes
	if [ -z "${cls}" ]; then
		# New classes to expand from debconf
		new_classes=$(classes | join_semi)
	else
		# New classes to expand from argument
		new_classes="${cls}"
		# Keep old classes
		old_classes=$(classes | join_semi)
	fi
	new_classes=$(expandclasses "${new_classes}" | sieve | join_semi)
	merged_classes=$(split_semi "${old_classes};${new_classes}" | sieve | join_semi)

	# Now that we've worked out the class list, store it for later
	# use.
	# If no classes were previously defined, we'll have to
	# register the question
	db_really_set auto-install/classes "${merged_classes}" "true"
	# Output newly added classes
	echo "${new_classes}"
}

load_preseed() {
	local seed="${1}"
	local checksum="${2}"
	[ -n "${seed}" ] && preseed_location "${seed}" "${checksum}"
}

safe_load_preseed() {
	# Never fail
	local seed="${1}"
	local checksum="${2}"
	[ -n "${seed}" ] || return 0
	preseed_fetch "${seed}" /tmp/.test_fetch \
	    || { [ $? = 4 ] && return 0; }
	preseed_location "${seed}" "${checksum}"
}

load_classes() {
	local classes="${1}"
	local include
	local cls
	# generate class preseed inclusion list
	for cls in $(split_semi "${classes}") ; do
		if expr "${cls}" : virtual/ >/dev/null; then
			echo "debug: no load of virtual “${cls}”"
			continue
		fi
		checkflag dbg/pauses all classes \
		    && pause "Load preseed “${cls}”" 'Class loading'
		include=''
		if expr "${cls}" : local/ >/dev/null; then
			include="/${cls}/preseed"
		else
			include="classes/${cls}/preseed"
		fi
		# ... and load them
		[ -n "${include}" ] && load_preseed "${include}"
	done
	# Do not fails after last test
	return 0
}
