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

Sends HEAD requests and follows redirects - as long as the link redirects and succeeds it'll still pass
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file_or_directory> <find_options>]"

help_usage "$@"

#min_args 1 "$@"

section "URL Link Checks"

start_time="$(start_timer)"

startpath="${1:-.}"
shift || :

trap_cmd 'echo >&2'

check_url_link(){
    local url="$1"
    local output
    output='.'
    if [ -n "${VERBOSE:-}" ] || [ -n "${DEBUG:-}" ]; then
        echo -n "$url => "
        output='%{http_code}\n'
    fi
    if ! command curl -sSIL "$url" -o /dev/null -w "$output"; then
        echo >&2
        echo "Broken Link: $url" >&2
        echo >&2
        return 1
    fi
}

urls="$(
    while read -r filename; do
        # $url_regex defined in lib/utils.sh
        # shellcheck disable=SC2154
        grep -Eo "$url_regex" "$filename" |
        grep -Ev -e 'localhost' \
                 -e '127.0.0.1' \
                 -e 'x\.x\.x\.x'
    done < <(find -L "$startpath" -type f "$@" | grep -v -e '/\.git/' -e '/\.svn/' -e '/\.hg/') |
    sort -u
)"

url_count="$(wc -l <<< "$urls" | sed 's/[[:space:]]//g')"

timestamp "Checking $url_count unique URLs"
echo >&2

tests=$(
while read -r url; do
    echo "check_url_link '$url'"
done <<< "$urls"
)

# export function to use in parallel
export -f check_url_link

set +e
parallel -j 10 <<< "$tests"
exit_code=$?
set -e
echo >&2
time_taken "$start_time"
echo >&2
if [ $exit_code -eq 0 ]; then
    section2 "URL links passed"
else
    echo "ERROR: Broken links detected!" >&2
    echo >&2
    section2 "URL links FAILED"
    exit 1
fi
