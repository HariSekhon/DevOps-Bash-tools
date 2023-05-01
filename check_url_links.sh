#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-17 18:11:09 +0000 (Mon, 17 Jan 2022)
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
Checks for broken URL links in a given file or directory tree

Sends HEAD requests and follows redirects - as long as the link redirects and succeeds it'll still pass, as this is most relevant to users and READMEs

Accepts HTTP 2xx/3xx status codes as well as the following to avoid false positives:
- HTTP 400 (bad request) - eg. a valid API URL may complain we're not sending the required parameters/headers/post body
- HTTP 401 (unauthorized)
- HTTP 403 (forbidden)
- HTTP 405 (method not allowed, ie. HEAD)
- HTTP 429 (rate limiting)

Ignores:
- Private addresses (localhost, .local, .svc, .cluster.local)
- Loopback IP (127.0.0.1)
- Private IPs (10.x.x.x, 172.16.x.x, 192.168.x.x)
- APIPA IPs (169.254.x.x)

To ignore links created with variables or otherwise composed in a way we can't straight test them, you can set URL_LINKS_IGNORED to a list, one per line of the URLs
To ignore links without dots in them, ie. not public URLs such as domains or IP addresses, which are most likely internal shortname services, set IGNORE_URLS_WITHOUT_DOTS to any value

If run in CI, runs 'git ls-files' to avoid scanning other local checkouts or git submodules
If you want to filter to specific files only, such a README.md, you can set URL_LINKS_FILE_FILTER='README.md' by name or path or ERE regex

Examples:

    # Scan all URLs in all files under your \$PWD, or in CI all committed files under your \$PWD

        ${0##*/}

    # Scan URLs in all files found under the 'src' directory

        ${0##*/} src

    # Scan URLs in all files called README.md under your local directory (local mode only, not CI)

        ${0##*/} . -name README.md

    # Ignore URLs we know won't work because they're samples / fake or constructed with variables we can't determine etc:

        export URL_LINKS_IGNORED='
            http://myplaceholder
            nonexistent.com
            https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
            https://some.website.com/downloads/v\$version/some.tar.gz
        '

        ${0##*/}
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

check_bin curl

check_url_link(){
    local url="$1"
    if [ -n "${VERBOSE:-}" ] || [ -n "${DEBUG:-}" ]; then
        echo -n "$url => " >&2
    fi
    status_code="$(command curl -sSILf --retry 3 --retry-delay 2 "$url" -o /dev/null -w "%{http_code}" 2>/dev/null || :)"
    if [ -n "${VERBOSE:-}" ] || [ -n "${DEBUG:-}" ]; then
        echo "$status_code" >&2
    else
        echo -n '.' >&2
    fi
    # DockerHub https://registry.hub.docker.com/v2 returns 401
    # GitHub returns HTTP 429 for too many requests
    if ! [[ "$status_code" =~ ^([23][[:digit:]]{2}|400|401|403|405|429)$ ]]; then
        echo >&2
        echo "Broken Link: $url" >&2
        echo >&2
        echo 1
        return 1
    fi
}

# Mac's BSD grep has a bug around -f ignores
if is_mac; then
    grep(){
        command ggrep "$@"
    }
fi

timestamp "Aggregating unique URLs from files under '$startpath'"
# filtering out LinkedIn.com which prevents crawling with HTTP/2 999 code
#               GitHub returns HTTP 429 for too many requests
                #-e 'https://github\.com/marketplace' \
urls="$(
    if is_CI; then
        git ls-files "$startpath" "$@"
    else
        find -L "$startpath" -type f "$@" |
        { grep -v -e '/\.git/' -e '/\.svn/' -e '/\.hg/' || : ; }
    fi |
    if [ -n "${URL_LINKS_FILE_FILTER:-}" ]; then
        grep -E "$URL_LINKS_FILE_FILTER" || :
    else
        cat
    fi |
    while read -r filename; do
        [ -f "$filename" ] || continue  # protects against symlinks to dirs returned by 'git ls-files'
        # $url_regex defined in lib/utils.sh
        # shellcheck disable=SC2154
        { grep -E "$url_regex" "$filename" || : ; } |
        #sed 's/#.*//; /^[[:space:]]*$/d' |
        { grep -Eiv \
             -e '\$' \
             -e 'localhost' \
             -e '\.svc$' \
             -e '.local$' \
             -e '\.cluster\.local' \
             -e 'domain\.com' \
             -e 'acmecorp\.com' \
             -e 'example\.com' \
             -e 'linkedin\.com' \
             -e '(169\.254\.)' \
             -e '(172\.16\.)' \
             -e '(192\.168\.)' \
             -e '10\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+' \
             -e '127.0.0.1' \
             -e '\.\.\.' \
             -e 'x\.x\.x\.x' || : ; } |
        { grep -Eo "$url_regex" || : ; } |
        if [ -n "${URL_LINKS_IGNORED:-}" ]; then
            grep -Eivf <(
                tr '[:space:]' '\n' <<< "$URL_LINKS_IGNORED" |
                sed 's/^[[:space:]]*//;
                     s/[[:space:]]*$//;
                     /^[[:space:]]*$/d'
            )
        else
            cat
        fi |
        if [ -n "${IGNORE_URLS_WITHOUT_DOTS:-}" ]; then
            grep -E 'https?://[^/]+\.[^/]+' || :
        else
            cat
        fi
    done |
    sort -uf
)"
urls="${urls##[[:space:]]}"
urls="${urls%%[[:space:]]}"
echo >&2

if is_blank "$urls"; then
    echo "No URLs found" >&2
    exit 0
fi

url_count="$(wc -l <<< "$urls" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

timestamp "Checking $url_count unique URLs"
echo >&2

tests=$(
while read -r url; do
    echo "check_url_link '$url'"
done <<< "$urls"
)

# export function to use in parallel
export -f check_url_link
export SHELL=/bin/bash  # Debian docker container doesn't set this and defaults to sh, failing to find exported function

set +eo pipefail
tally="$(parallel -j 10 <<< "$tests")"
exit_code=$?
set -eo pipefail

broken_count="$(awk '{sum+=$1} END{print sum}' <<< "$tally")"

echo >&2
time_taken "$start_time"
echo >&2

if [ $exit_code -eq 0 ]; then
    section2 "URL links passed"
else
    echo "ERROR: $broken_count/$url_count broken links detected!" >&2
    echo >&2
    section2 "URL Links FAILED"
    exit 1
fi
