#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-25 02:27:53 +0200 (Fri, 25 Oct 2024)
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
Copies a GitHub URL file's contents to the clipboard,
converting the URL to a raw GitHub content URL where necessary

Designed to quickly and easily copy link content into HariSekhon/Knowledge-Base repo
eg. for HariSekhon/SQL-scripts references to be easily copyable code blocks without having to follow links

GitHub URL can be passed as an arg or read from standard input

Tip: add this to a hotkey in your editor or IDE

Limitation: only tested on public GitHub repos
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<url_to_repo_file>]"

help_usage "$@"

max_args 1 "$@"

url="$("$srcdir/../bin/urlextract.sh" "$@" | head -n1)"

if ! [[ "$url" =~ ^https://(github\.com|raw.githubusercontent.com)/ ]]; then
    usage "Non-GitHub URL passed as first argument, must start with https://github.com or https://raw.githubusercontent.com/"
fi

if [[ "$url" =~ github\.com ]]; then
    url_orig="$url"
    url="${url//github.com/raw.githubusercontent.com}"
    # need more advanced replace
    # shellcheck disable=SC2001
    #url="$(sed 's|/blob/[^/]*/||' <<< "$url")"
    url="${url//\/blob\//\/}"
    log "Converted '$url_orig'
                            to '$url'"
fi

curl -sSf "$url" |
"$srcdir/../bin/copy_to_clipboard.sh"

bytes="$("$srcdir/../bin/paste_from_clipboard.sh" | wc -c | sed 's/[[:space:]]//g')"

timestamp "Copied '$url' to clipboard: $bytes bytes"
