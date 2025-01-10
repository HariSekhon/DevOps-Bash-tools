#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-11 01:56:41 +0700 (Sat, 11 Jan 2025)
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
Extracts the URLs from a given string arg, file or standard input,
queries each one and outputs the entire contents to stdout with the urls replaced by the redirected urls

Uses adjacent scripts:

    urlextract.sh

    url_extract_redirects.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<url_or_file_with_url>]"

help_usage "$@"

max_args 1 "$@"

arg="${1:-}"

contents="$(
    if [ $# -eq 0 ]; then
        cat
    elif [ -f "$arg" ]; then
        cat "$arg"
    else
        echo "$arg"
    fi
)"

sed_script=""

urls_seen=""

timestamp "Resolving URLs in contents to figure out what to replace, this may take some time. To see progress resolving each URL, set environment variable VERBOSE=1"
while read -r line; do
    url="$("$srcdir/urlextract.sh" <<< "$line" 2>/dev/null || :)"
    if ! is_blank "$url"; then
        if grep -Fxq "$url" <<< "$urls_seen"; then
            log "Skipping URL already resolved: $url"
            continue
        fi
        redirect_url="$("$srcdir/url_extract_redirects.sh" <<< "$url")"
        if [ "$redirect_url" != "$url" ]; then
            sed_script+="
                s|$url|$redirect_url|g
            "
        fi
    fi
    urls_seen+="
$url"
done <<< "$contents"

# shellcheck disable=SC2001
sed_script="$(sed "s/^[[:space:]]*//" <<< "$sed_script")"

# order sed script by longest lines first to avoid replacing substrings
# it is safer to replace the longest matches first
sed_script="$(awk '{ print length, $0 }' <<< "$sed_script" | sort -nr | cut -d' ' -f2-)"

sed "$sed_script" <<< "$contents"
