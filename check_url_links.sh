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
Checks for broken URL links in a given file or directory tree

Sends HEAD requests and follows redirects - as long as the link redirects and succeeds it'll still pass, as this is most relevant to users and READMEs

Accepts HTTP 2xx/3xx status codes as well as HTTP 429 (rate limiting) to avoid false positives

To ignore links created with variables or otherwise composed in a way we can't straight test them, you can set URL_LINKS_IGNORED to a list, one per line of the URLs

If run in CI, runs 'git ls-files' to avoid scanning other local checkouts or git  submodules

Examples:

    # Scan all URLs in all files under your \$PWD, or in CI all committed files under your \$PWD

        ${0##*/}

    # Scan URLs in all files found under the 'src' directory

        ${0##*/} src

    # Scan URLs in all files called README.md under your local directory (local mode only, not CI)

        ${0##*/} . -name README.md
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file_or_directory> <find_or_git_options>]"

help_usage "$@"

#min_args 1 "$@"

section "URL Link Checks"

start_time="$(start_timer)"

startpath="${1:-.}"
shift || :

trap_cmd 'echo >&2'

check_url_link(){
    local url="$1"
    if [ -n "${VERBOSE:-}" ] || [ -n "${DEBUG:-}" ]; then
        echo -n "$url => "
    fi
    status_code="$(command curl -sSILf --retry 3 --retry-delay 2 "$url" -o /dev/null -w "%{http_code}" || :)"
    if [ -n "${VERBOSE:-}" ] || [ -n "${DEBUG:-}" ]; then
        echo "$status_code"
    else
        echo -n '.'
    fi
    # GitHub returns HTTP 429 for too many requests
    if ! [[ $status_code =~ ^(429|[23][[:digit:]]{2})$ ]]; then
        echo >&2
        echo "Broken Link: $url" >&2
        echo >&2
        return 1
    fi
}

# Mac's BSD grep has a bug around -f ignores
if is_mac; then
    grep(){
        command ggrep "$@"
    }
fi

# filtering out LinkedIn.com which prevents crawling with HTTP/2 999 code
#               GitHub returns HTTP 429 for too many requests
                #-e 'https://github\.com/marketplace' \
urls="$(
    while read -r filename; do
        # $url_regex defined in lib/utils.sh
        # shellcheck disable=SC2154
        grep -Eo "$url_regex" "$filename" |
        grep -Eiv \
             -e 'localhost' \
             -e 'domain\.com' \
             -e 'linkedin\.com' \
             -e '127.0.0.1' \
             -e '\.\.\.' \
             -e 'x\.x\.x\.x' |
        if [ -n "${URL_LINKS_IGNORED:-}" ]; then
            grep -Eivf <(sed 's/^[[:space:]]*//;
                              s/[[:space:]]*$//;
                              /^[[:space:]]*$/d' <<< "$URL_LINKS_IGNORED")
        else
            cat
        fi
    done < <(
        if is_CI; then
            git ls-files "$startpath" "$@"
        else
            find -L "$startpath" -type f "$@" | grep -v -e '/\.git/' -e '/\.svn/' -e '/\.hg/'
        fi
    ) |
    sort -uf
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
    section2 "URL Links FAILED"
    exit 1
fi
