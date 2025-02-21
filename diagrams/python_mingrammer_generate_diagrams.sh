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
Generates all Python Mingrammer .py diagrams found under the current or given directory

Checks the python files contain either:

import diagrams

or

from diagrams import ...


Set SKIP_FILENAME_REGEX environment variable to exclude trying to generate your base templates
or similar that which are likely to fail for having a superset of example code in them

    export SKIP_FILENAME_REGEX='template.py|diagram.py'

Ported from Makefile in:

    https://github.com/HariSekhon/Diagrams-as-Code
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<source_dir>]"

help_usage "$@"

max_args 1 "$@"

# HariSekhon/Diagrams-as-Code python diagrams are set to auto-open unless this is set
export CI=1

src_dir="${1:-.}"

echo ==========================
echo Generating Python Diagrams
echo ==========================

cd "$src_dir"

exitcode=0

while read -r filename; do
    if ! grep -Eq \
        -e '^[[:space:]]*import[[:space:]]+diagrams[[:space:]]*$' \
        -e '^[[:space:]]*from[[:space:]]+diagrams[[:space:]]+import[[:space:]]+' \
        "$filename"; then
        log "Skipping Python file without any 'diagrams' imports: $filename"
        continue
    fi
    if [ -n "${SKIP_FILENAME_REGEX:-}" ]; then
        if [[ "$filename" =~ $SKIP_FILENAME_REGEX ]]; then
            continue
        fi
    fi
    timestamp "Generating: $filename"
    if ! python "$filename"; then
        timestamp "Failed to generate: $filename"
        exitcode=1
    fi
done < <(find . -type f -iname '*.py')

exit "$exitcode"
