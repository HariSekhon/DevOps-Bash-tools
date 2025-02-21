#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-05 19:16:39 +0700 (Wed, 05 Feb 2025)
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
Generates D2lang diagram and then opens the resulting image

If the .d2 file is set executable, runs it as is,
otherwise checks for shebang, sets executable if present and runs it,
otherwise falls back to a stock d2 build
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<file.d2> [<file2.d2>]"

help_usage "$@"

min_args 1 "$@"

if ! type -P d2 &>/dev/null; then
    timestamp "D2lang binary 'd2' not found in \$PATH, attempting to install via package manager"
    "$srcdir/../packages/install_packages.sh" d2
    echo >&2
fi

for arg in "$@"; do
    if ! [ -f "$arg" ]; then
        warn "not a file, skipping: $arg"
        continue
    fi
    filename="$arg"
    if ! [ -s "$filename" ]; then
        warn "file is empty, skipping: $filename"
        continue
    fi
    if ! [[ "$filename" =~ \.d2$ ]]; then
        warn "not a D2lang file ending in .d2, skipping: $filename"
        continue
    fi
    header_line="$(head -n1 "$filename")"
    #if [ "${header_line:0:2}" = '#!' ]; then
    if [[ "$header_line" = ^#!.+d2 ]]; then
        if ! [ -x "$filename" ]; then
            timestamp "Shebang detected but not executable, setting executable bit on: $filename"
            chmod +x "$filename"
        fi
        filepath="$(readlink -f "$filename")"
        timestamp "Running shebang: $filepath"
        "$filepath"
    else
        timestamp "Running default d2 build: $filename"
        d2 "$filename"
    fi
    file_basename="${filename%.*}"
    # shellcheck disable=SC2012
    # ls returns exit 1 when one of the paths isn't found, so ignore its exit code and look for blank
    generated_image="$(ls -t "$file_basename".png "$file_basename".svg 2>/dev/null | head -n1 || :)"
    if is_blank "$generated_image"; then
        die "Failed to find generated image for: $filename"
    fi
    timestamp "Opening: $generated_image"
    "$srcdir/imageopen.sh" "$generated_image"
done
