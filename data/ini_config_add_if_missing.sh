#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-20 20:47:15 +0400 (Wed, 20 Nov 2024)
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
Reads INI config blocks from stdin and appends them to the specified file if the section is not found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<file>"

help_usage "$@"

num_args 1 "$@"

file="$1"

mkdir -p -v "$(dirname "$file")"

touch "$file"

add_section=0

timestamp "Loading any missing ini config sections to $file"

while read -r line; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    if [[ $line =~ \[(.*)\] ]]; then
        section="${BASH_REMATCH[1]}"
        section_shortname="$section"
        section_brackets="[$section]"

        if [ "${SECTION_PREFIX:-}" ]; then
            # Convert to AWS config-style profile section
            if ! [[ $section =~ ${SECTION_PREFIX}[[:space:]].+ ]]; then
                section_brackets="[$SECTION_PREFIX $section]"
            else
                section_brackets="[$section]"
            fi
            # shellcheck disable=SC2295
            section_shortname="${section#$SECTION_PREFIX}"
            section_shortname="${section_shortname## }"
        fi

        # Check if the config block already exists in the file
        if grep -Fq "$section_brackets" "$file"; then
            timestamp "Config block '$section_shortname' already found"
            add_section=0
        else
            timestamp "Adding missing config block: $section_brackets"
            echo >> "$file"
            echo "$section_brackets" >> "$file"
            add_section=1
        fi
    elif [ "$add_section" = 1 ]; then
        # Append the content of the file
        echo "$line" >> "$file"
    fi
done
