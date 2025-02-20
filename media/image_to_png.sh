#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-06 20:51:19 +0400 (Wed, 06 Nov 2024)
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
Converts an image to PNG to be usable on websites that don't support the original image format,
such as LinkedIn, Medium or Reddit

Opens the converted PNG image to verify it

Requires ImageMagick to be installed, attempts to install it if not found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

num_args 1 "$@"

image="$1"

# because shopt -s nocasematch doesn't work on bash native string manipulation during testing
# shellcheck disable=SC2001
png="$(sed 's/\.[^.]\+$//i' <<< "$image").png"

if [ -f "$png" ]; then
    die "$png already exists, aborting..."
fi

converted=0

convert(){
    if [ -f "$png" ]; then
        die "$png already exists, aborting..."
    fi
    # can add other tools here later if wanted
    if type -P magick &>/dev/null; then
        timestamp "Converting '$image' to '$png' using ImageMagick"
        magick "$image" "$png"
        return 0
    fi
    timestamp "No tool found installed to convert image to png"
    return 1
}

if convert; then
    converted=1
else
    "$srcdir/../packages/install_packages.sh" imagemagick ||
    # can add other tools here later if wanted
    #"$srcdir/../packages/install_packages.sh" anothertool ||
    die "Failed to install ImageMagick to convert image to PNG"

    if is_mac; then
        "$srcdir/../packages/install_package_if_absent.sh" libheif
    fi

    if convert; then
        converted=1
    fi
fi

if [ "$converted" = 1 ]; then
    if [ -f "$png" ]; then
        timestamp "Conversion complete, file available: $png"
    else
        die "Conversion failed. Did not find expected file: $png"
    fi
else
    die "Conversion failed"
fi

timestamp "Opening image: $png"
"$srcdir/imageopen.sh" "$png"
