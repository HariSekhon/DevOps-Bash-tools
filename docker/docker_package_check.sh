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
Runs package installs on the last 8 major versions of a given docker image to check given packages are available
before adding them and breaking builds across distro versions

Uses adjacent scripts:

    ../bin/linux_distro_versions.sh

    ../packages/install_packages.sh

to install the packages using whatever local package manager is detected

Set environment variable MAX_VERSIONS to change the number of distro versions to run against (default: 8)

Currently only supports DockerHub images
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<image> <package1> [<package2> <package3> ...]"

help_usage "$@"

min_args 2 "$@"

image="$1"
shift || :

max_versions="${MAX_VERSIONS:-8}"

if ! is_int "$max_versions"; then
    die "MAX_VERSIONS may only be set to an integer, not: $max_versions"
fi

check_bin docker

if [[ "$image" =~ alpine ]]; then
    major_versions="$("$srcdir/../bin/linux_distro_versions.sh" alpine)"
elif [[ "$image" =~ debian ]]; then
    major_versions="$("$srcdir/../bin/linux_distro_versions.sh" debian)"
elif [[ "$image" =~ ubuntu ]]; then
    major_versions="$("$srcdir/../bin/linux_distro_versions.sh" ubuntu)"
elif [[ "$image" =~ fedora ]]; then
    major_versions="$("$srcdir/../bin/linux_distro_versions.sh" fedora)"
elif [[ "$image" =~ centos ]]; then
    major_versions="$("$srcdir/../bin/linux_distro_versions.sh" centos)"
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

major_versions="$(head -n "$max_versions" <<< "$major_versions")"

echo
timestamp "Running for major versions:"
echo
echo "$major_versions"

for version in $major_versions; do
    echo
    timestamp "Launching docker container for '$image:$version'"
    docker run -ti --rm -v "$srcdir/..":/pwd -w /pwd "$image:$version" packages/install_packages.sh "$@"
done
