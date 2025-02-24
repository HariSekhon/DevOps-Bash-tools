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
Generates a markdown index list from the headings in a given markdown file such as README.md

If no file is given but README.md is found in the \$PWD, then uses that

Defaults to 2 space indentation, but if you want to override that to shut up mdl rule, you can:

    export MARKDOWN_INDENTATION=3
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<README.md>]"

help_usage "$@"

max_args 1 "$@"

markdown_file="${1:-README.md}"

# prefer 2 but working around this annoying:
#
#   https://github.com/markdownlint/markdownlint/blob/main/docs/RULES.md#md007---unordered-list-indentation
#
indent_width="${MARKDOWN_INDENTATION:-2}"

if ! is_int "$indent_width"; then
    die "Indent width must be a valid integer, not: $indent_width"
fi

if ! [ -f "$markdown_file" ]; then
    die "File not found: $markdown_file"
fi

# since we now strip ```code``` blocks we must ensure that they match otherwise this code cannot
# reliably run as it'll result in stripping out valid headings

if [ "$(( $(grep -c '^[[:space:]]*```' "$markdown_file") % 2))" != 0 ]; then
    die "Error - uneven number of code blocks found in file: $markdown_file"
fi

# sed strip out ```code``` blocks to avoid # comments inside code blocks from going into the index
# tail -n +2 takes off the first line which is the header we definitely don't want in the index
# false positive
# shellcheck disable=SC2016
sed '/^[[:space:]]*```/,/^[[:space:]]*```/d' "$markdown_file" |
# strip out oneline html comment because next sed will strip to end of file otherwise
sed '/<!--.*-->/d;' |
# strip out <!-- commented out --> sections
sed '/<!--/,/-->/d' |
grep -E -e '^#+[[:space:]]' -e '<h[[:digit:]] id=' |
tail -n +2 |
# don't include main headings
#sed '/^#[[:space:]]/d' |
# don't include the Index title itself either
sed '/^[#[:space:]]*Index$/d' |
while read -r line; do
    # support HTML tags (currently only on same line)
    if [[ "$line" =~ \<h[[:digit:]][[:space:]]+id= ]]; then
        level=${line#<h}
        level=${level%% *}
        title=${line#*>}
        title=${title%%</h*}
        link=${line#*id=\"}
        link=${link%%\"*}
    else
        level="$(grep -Eo '^#+' <<< "$line" | tr -d '[:space:]' | wc -c)"
        level="${level//[[:space:]]}"
        #if [ "$level" -gt 3 ]; then
        #    continue
        #fi
        #title="${line##*# }"
        title="$(sed '
            # strip anchor prefixes
            s/^##* //;
            # change text links like [ZooKeeper](zookeeper.md) to just ZooKeeper
            s/\[\([^]]\+\)\]([[:alnum:]:\/#?.=-]\+)/\1/g;
        ' <<< "$line")"
        # create relative links of just the anchor and not the repo URL prefix, it's more portable
        link="$(
            sed '
                s/^#*[[:space:]]*//;
            ' <<< "$title" |
            tr '[:upper:]' '[:lower:]' |
            sed '
                s/[^[:alnum:][:space:]_-]//g;
                s/[[:space:]-]/-/g;
                s/^/#/;
            '
        )"
    fi
    indentation=$(( indent_width * ( level - 2 ) ))
    if [ "$indentation" -gt 0 ]; then
        printf "%${indentation}s" " "
    fi
    printf -- "- [%s](%s)\n" "$title" "$link"
done
