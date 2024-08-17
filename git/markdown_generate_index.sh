#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-05-14 17:53:42 +0100 (Sun, 14 May 2023)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
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
Generates a markdown index list from the headings in a given README.md file

If no file is given but one is found in the \$PWD, then uses that
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<README.md>"

help_usage "$@"

max_args 1 "$@"

readme="${1:-README.md}"

indent_width=2

# tail -n +2 takes off the first line which is the header we definitely don't want in the index
grep '^#' "$readme" |
tail -n +2 |
# don't include main headings
#sed '/^#[[:space:]]/d' |
# don't include the Index title itself either
sed '/^[#[:space:]]*Index$/d' |
while read -r line; do
    level="$(grep -Eo '^#+' <<< "$line" | tr -d '[:space:]' | wc -c)"
    level="${level//[[:space:]]}"
    if [ "$level" -gt 3 ]; then
        continue
    fi
    title="${line##*# }"
    # create relative links of just the anchor and not the repo URL prefix, it's more portable
    link="$(
        sed '
            s/^#*[[:space:]]*//;
        ' <<< "$line" |
        tr '[:upper:]' '[:lower:]' |
        sed '
            s/[^[:alnum:][:space:]-]//g;
            s/[[:space:]-]/-/g;
            s/^/#/
        '
    )"
    indentation=$(( indent_width * ( level - 2 ) ))
    if [ $indentation -gt 0 ]; then
        printf "%${indentation}s" " "
    fi
    printf -- "- [%s](%s)\n" "$title" "$link"
done
