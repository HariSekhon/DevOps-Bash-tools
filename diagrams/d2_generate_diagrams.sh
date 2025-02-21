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
Generates all .d2 diagrams found under the current or given directory

Set SKIP_FILENAME_REGEX environment variable to exclude trying to generate your base templates
or similar that which are likely to fail for having a superset of example code in them

    export SKIP_FILENAME_REGEX='template.d2|diagram.d2'

Ported from Makefile in:

    https://github.com/HariSekhon/Diagrams-as-Code

because started getting more complicated with error handling and revertion on incorrectly generated diagrams,
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

if ! type -P d2 &>/dev/null; then
    "$srcdir/../install/install_d2.sh"
fi

echo ======================
echo Generating D2 Diagrams
echo ======================

mkdir -p -v "$target_dir"

# workaround to use shebang because d2 doesn't currently support defining the theme in the .d2 file
# and also doesn't support having a separate images/ directory, see:
#
#	https://github.com/terrastruct/d2/issues/1286
#
#	https://github.com/terrastruct/d2/issues/1287
#
#	https://github.com/terrastruct/d2/issues/1288
#
#if [ -x "$x" ]; then
#    ./"$x"
#fi

exitcode=0

while read -r filename; do
    if [ -n "${SKIP_FILENAME_REGEX:-}" ]; then
        if [[ "$filename" =~ $SKIP_FILENAME_REGEX ]]; then
            continue
        fi
    fi
    if [ "$target_dir" = . ]; then
        img="${filename%.d2}.$ext"
    else
        basename="${filename##*/}"
        img="$target_dir/${basename%.d2}.$ext"
    fi
    shebang="$(
        head -n 1 "$filename" |
        awk '/^#!\/.*d2/{print}' |
        sed 's/^#!//'
    )"
    if [ -z "$shebang" ]; then
        #shebang="d2 --theme 200"
        shebang="d2"
    fi
    timestamp "Generating: $filename -> $img"
    if ! $shebang "$filename" "$img"; then
        timestamp "Failed to generate: $img"
        git checkout "$img" 2>/dev/null ||
        rm -fv "$img"
        exitcode=1
    fi
done < <(find "$src_dir" -type f -iname '*.d2')

exit "$exitcode"
