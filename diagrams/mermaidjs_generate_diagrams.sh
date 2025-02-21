#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-22 00:22:08 +0700 (Sat, 22 Feb 2025)
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
Generates all MermaidJS .mmd diagrams found under the current or given directory

Set SKIP_FILENAME_REGEX environment variable to exclude trying to generate your base templates
or similar that which are likely to fail for having a superset of example code in them

    export SKIP_FILENAME_REGEX='template.mmd|diagram.mmd'

Ported from Makefile in:

    https://github.com/HariSekhon/Diagrams-as-Code

because started getting more complicated with error handling and revertion of incorrectly generated diagrams,
for which a Makefile is not the best to do long multi-line code blocks
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<source_dir> <target_dir> <png|svg>]"

help_usage "$@"

max_args 3 "$@"

src_dir="${1:-.}"
target_dir="${2:-.}"
ext="${3:-svg}"

target_dir="${target_dir%%/}"

if ! [[ "$ext" =~ ^(png|svg)$ ]]; then
    die "Invalid extension specified: must be 'png' or 'svg'"
fi

if ! type -P mmdc &>/dev/null; then
    "$srcdir/../install/install_mermaidjs.sh"
fi

echo =============================
echo Generating MermaidJS Diagrams
echo =============================

mkdir -p -v "$target_dir"

exitcode=0

while read -r filename; do
    if [ -n "${SKIP_FILENAME_REGEX:-}" ]; then
        if [[ "$filename" =~ $SKIP_FILENAME_REGEX ]]; then
            continue
        fi
    fi
    if [ "$target_dir" = . ]; then
        img="${filename%.mmd}.$ext"
    else
        basename="${filename##*/}"
        img="$target_dir/${basename%.mmd}.$ext"
    fi
    timestamp "Generating: $filename -> $img"
    if ! mmdc -i "$filename" -o "$img"; then
        timestamp "Failed to generate: $img"
        git checkout "$img" 2>/dev/null ||
        rm -fv "$img"
        exitcode=1
    fi
done < <(find "$src_dir" -type f -iname '*.mmd')

exit "$exitcode"
