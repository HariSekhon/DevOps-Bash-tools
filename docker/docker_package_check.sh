#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: ubuntu pre-commit
#
#  Author: Hari Sekhon
#  Date: 2024-09-22 20:47:39 +0100 (Sun, 22 Sep 2024)
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
Runs package installs on all the major versions of a given docker image to check given packages
are available before adding them and breaking builds across distro versions

Uses adjacent script:

    ../packages/install_packages.sh

to install the packages using whatever local package manager is detected

Currently only supports DockerHub images
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image> <package1> [<package2> <package3> ...]"

help_usage "$@"

min_args 2 "$@"

image="$1"
shift || :

check_bin docker

if [[ "$image" =~ debian ]]; then
    timestamp "Debian detected, this has a huge DockerHub tag list which takes ages to iterate through the DockerHub API"
    timestamp "Optimization, pull major release list from debian.org instead"
    major_versions="latest
$(curl -sS https://www.debian.org/releases/ | grep -Eo 'Debian [[:digit:]]+' | sed 's/^Debian //')"
else
    timestamp "Querying DockerHub for major versions of image '$image'"
    major_versions="$(
        "$srcdir/../docker/dockerhub_list_tags.sh" "$image" |
        grep -Eo -e '^[[:digit:]]+(\.[[:digit:]]+)?$' \
                 -e '^latest$'
    )"
fi

if grep -Eq '^[[:digit:]]+$' <<< "$major_versions"; then
    timestamp "Major version tags detected, using only those to save time"
    major_versions="$(grep -EO -e '^[[:digit:]]+$' -e 'latest' <<< "$major_versions" | sort -Vr)"
fi

echo
timestamp "Running for major versions:"
echo
echo "$major_versions"
echo

for version in $major_versions; do
    echo
    timestamp "Launching docker container for '$image:$version'"
    docker run -ti --rm -v "$srcdir/..":/pwd -w /pwd "$image:$version" packages/install_packages.sh "$@"
done
