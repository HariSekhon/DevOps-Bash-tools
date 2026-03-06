#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: one%20two
#
#  Author: Hari Sekhon
#  Date: 2020-03-03 17:47:02 +0000 (Tue, 03 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Quick command line URL decoding

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
URL decodes the given string argument or standard input
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<string_to_urldecode>]"

help_usage "$@"

#min_args 1 "$@"

if [ $# -gt 0 ]; then
    echo "$@"
else
    cat
fi |
if type -P perl &>/dev/null &&
   perl -MURI::ESCAPE -e '' &>/dev/null; then
    perl -MURI::Escape -ne 'chomp; print uri_unescape($_) . "\n"'
elif type -p python3 &>/dev/null &&
     python3 -c 'from urllib.parse import quote_plus'; then
    python3 -c "import sys, urllib.parse; [print(urllib.parse.unquote(line.strip())) for line in sys.stdin]"
else
    echo "ERROR: neither Perl URI::Escape nor Python3 with UrlLib.Parse are available" >&2
    exit 1
fi
