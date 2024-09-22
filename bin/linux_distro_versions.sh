#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-22 21:24:35 +0100 (Sun, 22 Sep 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Quickly returns the list of major versions for a given Linux distro

Used by programs like ../docker_package_check.sh to get versions faster than iterating lots of tags on the DockerHub API

Currently supports:

- Alpine
- Debian
- Ubuntu
- Redhat
- Fedora
- CentOS
- Rocky Linux
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<distro_name>"

help_usage "$@"

num_args 1 "$@"

distro="$1"

shopt -s nocasematch
if [ "$distro" = alpine ]; then
    #curl -sS https://alpinelinux.org/releases/ |
    curl -sS https://dl-cdn.alpinelinux.org/alpine/ |
    grep -Eo 'v[[:digit:]]+\.[[:digit:]]+' |
    sed 's/^v//; s/[[:space:]]*$//'
elif [ "$distro" = debian ]; then
    curl -sS https://www.debian.org/releases/ |
    grep -Eo 'Debian [[:digit:]]+' |
    sed 's/^Debian //'
elif [ "$distro" = ubuntu ]; then
    curl -sS https://releases.ubuntu.com/ |
    grep -Eo 'Ubuntu [[:digit:]]+\.[[:digit:]]+' |
    sed 's/^Ubuntu //'
elif [ "$distro" = fedora ]; then
    curl -sS https://dl.fedoraproject.org/pub/fedora/linux/releases/ |
    grep -Eo '>[[:digit:]]+/<' |
    sed 's/^>//; s|/<$||'
elif [ "$distro" = redhat ]; then
    curl -sS https://access.redhat.com/articles/3078 |
    grep -Eo 'Red Hat Enterprise Linux [[:digit:]]+' |
    sed 's/Red Hat Enterprise Linux //; s/[[:space:]]*$//'
elif [ "$distro" = rocky ] || [ "$distro" = rockylinux ]; then
    #curl -sS https://wiki.rockylinux.org/rocky/version/ |
    #grep -Eo 'Rocky Linux [[:digit:]]+' |
    #sed 's/Rocky Linux //; s/[[:space:]]*$//'
    curl -sS https://dl.rockylinux.org/pub/rocky/ |
    grep -Eo '>[[:digit:]]+/<' |
    sed 's/^>//; s|/<$||'
elif [ "$distro" = centos ]; then
    # EOL so just print the known versions
    echo "5
6
7
8"
else
    usage "Unsupported Linux distro: $distro"
fi |
sort -Vur
