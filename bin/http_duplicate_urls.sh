#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-12-31 17:45:56 +0000 (Sun, 31 Dec 2023)
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
Finds duplicate URLs in a given web page

The output is sorted in ascending order of the number of duplicates found for each URL because on large web pages with lots of duplicates I tend to focus on the most duplicated URLs first which will then be right above your prompt for convenience

Feel free to sort or 'tac' to reverse the order, or you can use tail if you're only interested in the N most duplicated URLs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<url>"

help_usage "$@"

min_args 1 "$@"

url="$1"

curl "$url" |
grep -Eo 'https?://[^[:space:]"'"'"'<>]+' |
sort |
uniq -c |
sort -k1n |
grep -Ev '^[[:space:]]+1[[:space:]]+' || :
