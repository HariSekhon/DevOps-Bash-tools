#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 00:05:26 +0100 (Mon, 24 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu  #o pipefail  # not available in POSIX sh
if [ "${SHELL##*/}" = bash ]; then
    # shellcheck disable=SC2039
    set -o pipefail
fi
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/packages.sh"

# shellcheck disable=SC2154
usage(){
    cat <<EOF
Checks a given list of APK packages and returns those not installed

$package_args_description

Tested on Alpine


usage: ${0##*/} <packages>
EOF
    exit 3
}

for arg; do
    case "$arg" in
        -*)     usage
                ;;
    esac
done

installed_packages="$(mktemp)"
trap 'rm -f "$installed_packages"' EXIT

installed_apk > "$installed_packages"

process_package_args "$@" |
grep -vFx -f "$installed_packages" || :  # grep causes pipefail exit code breakages in calling code when it doesn't match
