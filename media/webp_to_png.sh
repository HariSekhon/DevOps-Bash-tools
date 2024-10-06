#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-06 12:20:08 +0300 (Sun, 06 Oct 2024)
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
Convert a Webp image to PNG to be usable on websites that don't support Webp images like Medium

Requires dwebp, attempts to install it if not found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

num_args 1 "$@"

webp="$1"

shopt -s nocasematch
if ! [[ "$webp" =~ \.webp$ ]]; then
    die "ERROR: file passed does not have an .webp file extension: $webp"
fi

# because shopt -s nocasematch doesn't work on bash native string manipulation during testing
# shellcheck disable=SC2001
png="$(sed 's/\.webp$//i' <<< "$webp").png"

if [ -f "$png" ]; then
    die "$png already exists, aborting..."
fi

if ! type -P dwebp &>/dev/null; then
    timestamp "'dwebp' command not found, attempting to install it"
    "$srcdir/../packages/install_packages.sh" dwebp
fi

timestamp "Converting '$webp' to PNG format"
if dwebp "$webp" -o "$png"; then
    if [ -f "$png" ]; then
        timestamp "Conversion complete, file available: $png"
    else
        die "Conversion failed. Did not find expected file: $png"
    fi
else
    die "Conversion failed"
fi
