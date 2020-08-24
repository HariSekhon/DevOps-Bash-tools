#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 21:31:10 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/packages.sh"

# shellcheck disable=SC2154
usage(){
    cat <<EOF
Installs Alpine APK package lists if the packages aren't already installed

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


process_package_args "$@" |
"$srcdir/apk_filter_not_installed.sh" |
xargs -r "$srcdir/apk_install_packages.sh"
