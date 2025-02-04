#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-04 18:03:29 +0700 (Tue, 04 Feb 2025)
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
Finds the latest Ubuntu full release version for a given major X.Y release eg. 22.04 => 22.04.6

If no major version is given, finds the latest major version and then the latest minor full version for that

Outputs the URL to the latest minor version ISO

Used to update repo:

    https://github.co/HariSekhon/Packer
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

max_args 1 "$@"

version="${1:-}"

base_url="https://cdimage.ubuntu.com/releases"

if is_blank "$version"; then
    timestamp "No version specified"
    timestamp "Finding latest major Ubuntu release by parsing: $base_url/"
    version="$(
        curl -s "$base_url/" |
            grep -oP 'href="\d{2}\.\d{2}/"' |
            grep -oP '\d{2}\.\d{2}' |
            sort -V |
            tail -n 1
    )"
    timestamp "Latest Ubuntu major version: $version"
fi

release_url="$base_url/$version/release"

timestamp "Finding latest Ubuntu minor release version by parsing: $release_url/"
full_version="$(
    curl -s "$release_url/" |
        grep -oP 'href=".*?\.iso"' |
        grep -oP '\d+\.\d+(\.\d+)?' |
        sort -V |
        tail -n 1
)"

if is_blank "$full_version"; then
    die "ERROR: Full version parsing failed for Ubuntu version: $version"
fi

timestamp "Latest Ubuntu full version for $version:"
echo >&2
echo "$full_version"
