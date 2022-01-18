#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-17 18:11:09 +0000 (Mon, 17 Jan 2022)
#
#  https://github.com/HariSekhon/Nagios-Plugins
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Checks for broken links in a given file or directory tree
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file_or_directory> <find_options>]"

help_usage "$@"

#min_args 1 "$@"

section "URL Link Checks"

start_time="$(start_timer)"

startpath="${1:-}"
shift || :

broken_links=0

check_url_links(){
    local filename="$1"
    # shellcheck disable=SC2154
    while read -r url; do
        if ! curl -sSI "$url" >/dev/null; then
            ((broken_links+=1))
            echo >&2
            echo "Broken Link: $url" >&2
        fi
        echo -n .
    done < <(grep -Eo "$url_regex" "$filename")
}

find -L "$startpath" -type f "$@" |
while read -r filename; do
    check_url_links "$filename"
done

if [ "$broken_links" != 0 ]; then
    echo
    die "$broken_links broken links detected!"
fi

time_taken "$start_time"
section2 "URL links passed"
echo
