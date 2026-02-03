#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-02-02 23:14:31 -0300 (Mon, 02 Feb 2026)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/packages.sh"

# shellcheck disable=SC2154
usage(){
    cat <<EOF
Upgrades Alpine APK package lists if the packages are outdated

This is slow because it has to do an 'apk update' to get the latest package list first
which can take 15 seconds if you're not on a fast connection

$package_args_description

Not yet tested on Alpine as new docker images have no outdated packages


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

apk update

upgradeable_packages="$(apk version -l '<')"

process_package_args "$@" |
while read -r package; do
    if echo "$upgradeable_packages" | grep -q "^$package-[[:digit:]]"; then
        echo "$package"
    fi
done |
xargs -r apk upgrade
