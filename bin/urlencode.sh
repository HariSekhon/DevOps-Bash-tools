#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: Sébastien Tellier
#
#  Author: Hari Sekhon
#  Date: 2020-03-03 17:47:02 +0000 (Tue, 03 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
URL encodes the given string argument or standard input

Only escapes characters disallowed in URIs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<string_to_urlencode>]"

help_usage "$@"

#min_args 1 "$@"

if [ $# -gt 0 ]; then
    echo "$@"
else
    cat
fi |
if type -P jq &>/dev/null; then
    jq -rn --arg string "$(cat)" '$string|@uri'
elif type -P perl &>/dev/null &&
   perl -MURI::ESCAPE -e '' &>/dev/null; then
    perl -MURI::Escape -ne 'chomp; print uri_escape($_) . "\n"'
elif type -p python3 &>/dev/null &&
     python3 -c 'from urllib.parse import quote_plus'; then
     python3 -c 'from urllib.parse import quote_plus; import sys; print(quote_plus(sys.stdin.read().rstrip("\n").rstrip("\r")))'
else
    echo "ERROR: neither Perl URI::Escape nor Python3 with UrlLib.Parse are available" >&2
    exit 1
fi
