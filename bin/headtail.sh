#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-25 19:03:48 +0100 (Sat, 25 Jul 2020)
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
Head and Tail input files or standard input

For a better version written in Python see the adjacent DevOps Python tools repo:

    https://github.com/HariSekhon/DevOps-Python-tools

For something as simple as just the first and last line, you could instead do:

    sed -n '1p;\$p'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[-n <num_lines>] [<file1> <file2> ...]

--num-lines     Number of lines to print from each file or stdin (default: 10)"


help_usage "$@"

files=()

until [ $# -lt 1 ]; do
    case "$1" in
     -n|--num)  num_lines="${2:-}"
                shift || :
                ;;
            *)  files+=("$1")
                ;;
    esac
    shift || :
done

num_lines="${num_lines:-10}"

docsep(){
    if [ "${#files[@]}" -gt 1 ]; then
        echo '======' >&2
    fi
}

if [ "${#files[@]}" -gt 0 ]; then
    for filename in "${files[@]}"; do
        if [ "$(wc -l "$filename" | awk '{print $1}')" -lt $((2*num_lines)) ]; then
            cat "$filename"
            continue
        fi
        head -n "$num_lines" "$filename"
        tail -n "$num_lines" "$filename"
        docsep
    done
else
    output="$(cat)"
    if [ "$(wc -l <<< "$output" | awk '{print $1}')" -lt $((2*num_lines)) ]; then
        echo "$output"
    else
        head -n "$num_lines" <<< "$output"
        tail -n "$num_lines" <<< "$output"
    fi
fi
