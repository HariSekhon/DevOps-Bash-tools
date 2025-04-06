#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-04-06 21:53:41 +0800 (Sun, 06 Apr 2025)
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
Converts <https://github.com/...> links in Markdown to shorthand links with an OctoCat emoji
and without the redundant https://github.com/ prefix

eg.

    <https://github.com/HariSekhon/Knowledge-Base>

        would become

    [:octocat: HariSekhon/Knowledge-Base](https://github.com/HariSekhon/Knowledge-Base)

This looks nicer and is shorter when rendered

If given a markdown file it will in-place edit the file to replace the references

If passed as string or stdin it will print to stdout
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file_or_string> <file2_or_string2> ...]"

help_usage "$@"

#min_args 1 "$@"

# replace <https://github.com/owner/repo> with [:octocat: owner/repo](https://github.com/owner/repo)
#
# ignores GitHub links that shouldn't be changed like https://github.com/settings/... in my Knowledge-Base repo
#
# ignores #readme or similar anchor suffixes and ?tab= parameters in the capture for the link text,
# but retains them for the link target
regex_script='
    /github\.com\/settings\// n;
    s|<\(https://github.com/\([^/]*/[^/?>#]*\)[^>]*\)>|[:octocat: \2](\1)|g
'

if [ $# -gt 0 ]; then
    for arg; do
        if [ -f "$arg" ]; then
            sed -i "$regex_script" "$arg"
        else
            sed "$regex_script" <<< "$arg"
        fi
    done
else
    warn "Reading from stdin"
    sed "$regex_script"
fi
