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
Converts an SVG image to PNG to be usable on websites that don't support SVG images like LinkedIn, Medium or Reddit

Requires one of Inkscape, ImageMagik or rsvg-convert - will attempt to use whichever is already installed
or install one of them if none are found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

num_args 1 "$@"

svg="$1"

shopt -s nocasematch
if ! [[ "$svg" =~ \.svg$ ]]; then
    die "ERROR: file passed does not have an .svg file extension: $svg"
fi

# because shopt -s nocasematch doesn't work on bash native string manipulation during testing
# shellcheck disable=SC2001
png="$(sed 's/\.svg$//i' <<< "$svg").png"

converted=0

convert(){
    if [ -f "$png" ]; then
        die "$png already exists, aborting..."
    fi
    if type -P magick &>/dev/null; then
        timestamp "Converting '$svg' to '$png' using ImageMagick"
        magick "$svg" "$png"
        return 0
    elif rsvg-convert &>/dev/null; then
        timestamp "Converting '$svg' to '$png' using rsvg-convert"
        rsvg-convert "$svg" -o "$png"
        return 0
    # heavy, try it last
    elif type -P inkscape &>/dev/null; then
        timestamp "Converting '$svg' to '$png' using Inkscape"
        inkscape "$svg" --export-filename="$png"
        return 0
    fi
    return 1
}

if convert; then
    converted=1
else
    "$srcdir/../packages/install_packages.sh" imagemagick ||
    # package on Debian / Ubuntu
    "$srcdir/../packages/install_packages.sh" rsvg-convert ||
    "$srcdir/../packages/install_packages.sh" inkscape ||
    die "Failed to install any of the usual tools to convert SVG to PNG"

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
