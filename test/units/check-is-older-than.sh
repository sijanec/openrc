#!/bin/sh
# unit test for is_older_than code of baselayout (2008/06/19)
# Author: Matthias Schwarzott <zzam@gentoo.org>

if [ -z "${BUILD_ROOT}" ]; then
	printf "%s\n" "BUILD_ROOT must be defined" >&2
	exit 1
fi
PATH="${BUILD_ROOT}"/src/is_older_than:${PATH}

TMPDIR="${BUILD_ROOT}"/tmp-"$(basename "$0")"

# Please note that we added this unit test because the function
# should really be called is_newer_than as it's what it's really testing.
# Or more perversly, returning 0 on failure and 1 and success.

# bool is_older_than(reference, files/dirs to check)
#
#   return 0 if any of the files/dirs are newer than
#   the reference file
#
#   EXAMPLE: if is_older_than a.out *.o ; then ...
ref_is_older_than()
{
	local x= ref="$1"
	shift

	for x; do
		[ "${x}" -nt "${ref}" ] && return 0
		if [ -d "${x}" ]; then
			ref_is_older_than "${ref}" "${x}"/* && return 0
		fi
	done
	return 1
}

do_test()
{
	local r1= r2=

	ref_is_older_than "$@"
	r1=$?
	is_older_than "$@"
	r2=$?

	[ -n "${VERBOSE}" ] &&
		printf "reference = %s  |  OpenRC = %s\n" "$r1" "$r2"
	[ $r1 = $r2 ]
}

echo_cmd()
{
	[ -n "${VERBOSE}" ] && printf "%s\n" "$@"
	"$@"
}

test_it()
{
	do_test "${TMPDIR}"/ref "${TMPDIR}"/dir1 "${TMPDIR}"/dir2
}

run_test()
{
	echo_cmd mkdir -p "${TMPDIR}"/dir1 "${TMPDIR}"/dir2
	echo_cmd touch "${TMPDIR}"/dir1/f1 "${TMPDIR}"/dir1/f2 \
		"${TMPDIR}"/dir1/f3 "${TMPDIR}"/dir2/f1 \
		"${TMPDIR}"/dir2/f2 "${TMPDIR}"/dir2/f3
	echo_cmd sleep 1
	echo_cmd touch "${TMPDIR}"/ref
	test_it || return 1

	echo_cmd sleep 1
	echo_cmd touch "${TMPDIR}"/dir1/f2
	test_it || return 1

	echo_cmd sleep 1
	echo_cmd touch "${TMPDIR}"/ref
	test_it || return 1

	echo_cmd sleep 1
	echo_cmd touch "${TMPDIR}"/dir2/f2
	test_it || return 1
}

rm -rf "${TMPDIR}"
mkdir "${TMPDIR}"
run_test
retval=$?
rm -rf "${TMPDIR}"
exit ${retval}
