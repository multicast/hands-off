#!/bin/sh
#
# Copyright © 2013-2016 Daniel Dehennin <daniel.dehennin@baby-gnu.org>
#
# Distributed under the terms of the GNU GPL version 2 or (at your
# option) any later version see the file "COPYING" for details

set -e

. /tmp/HandsOff-fn.sh

echo "debug: Running..."

PAUSE_TITLE='Per class scripts runner'
RUNNER_ID="${1}"
RUNNER_DESC="${2}"
RUNNER_FLAGS="${3}"

if [ -z "${RUNNER_ID}" -o -z "${RUNNER_DESC}" -o -z "${RUNNER_FLAGS}" ]
then
	error "Missing some arguments:
RUNNER_ID: ${RUNNER_ID}
RUNNER_DESC: ${RUNNER_DESC}
RUNNER_FLAGS: ${RUNNER_FAGS}"
	handsoff_poweroff
fi

pause_flags() {
	echo all $(split_semi "${RUNNER_FLAGS}")
}

debug_flags() {
	local flags
	for flag in $(pause_flags)
	do
		flags="${flags} ${flag}-x"
	done
	echo ${flags}
}

checkflag dbg/flags all-x runner-x $(debug_flags) \
    && set -x
checkflag dbg/pauses all runner $(pause_flags) \
    && pause "Run ${RUNNER_DESC} scripts" "${PAUSE_TITLE}"

db_register hands-off/meta/text hands-off/title
db_register hands-off/meta/text hands-off/item

db_subst hands-off/title DESC "Preseed ${RUNNER_ID}_script(s)"
db_progress START 0 $({ echo myself; classes; } | wc -w) hands-off/title

db_subst hands-off/item DESC "Running top level ${RUNNER_DESC} script"
db_progress INFO hands-off/item

db_progress STEP 1
# Chain onto class specific script(s) if any.
for class in $(classes)
do
	db_subst hands-off/item DESC \
		 "${RUNNER_DESC} script for class “${class}”"
	db_progress INFO hands-off/item

	if expr "${class}" : virtual/ >/dev/null; then
		echo "debug: no load of virtual “${cls}”"
		db_progress STEP 1
		continue
	elif expr "${class}" : local/ >/dev/null; then
		CLASS_SCRIPT_URL="/${class}/${RUNNER_ID}_script"
	else
		CLASS_SCRIPT_URL="/classes/${class}/${RUNNER_ID}_script"
	fi

	cl_a_ss=$(shell_escape "${class}")
	if ! preseed_fetch ${CHECKSUM_IF_AVAIL} "${CLASS_SCRIPT_URL}" \
	     "/tmp/${RUNNER_ID}_script-${cl_a_ss}"
	then
		echo "warning: ...${CLASS_SCRIPT_URL} not found"
		# Remove possible empty file
		rm -f "/tmp/${RUNNER_ID}_script-${cl_a_ss}"
	fi

	if [ -e "/tmp/${RUNNER_ID}_script-${cl_a_ss}" ]
	then
		checkflag dbg/pauses $(pause_flags) \
		    && pause "Running ${RUNNER_DESC} script for “${class}”" \
			     "${PAUSE_TITLE}"

		# Scripts can get their class name with “${class}”
		export class

		chmod +x "/tmp/${RUNNER_ID}_script-${cl_a_ss}"
		log-output -t "${class}/${RUNNER_ID}_script" \
			   "/tmp/${RUNNER_ID}_script-${cl_a_ss}"
	fi
	db_progress STEP 1
done

db_progress STOP
db_unregister hands-off/item
db_unregister hands-off/title

checkflag dbg/pauses all runner $(pause_flags) \
    && pause "End ${RUNNER_DESC} scripts" "${PAUSE_TITLE}"

echo "debug: completed successfully"
