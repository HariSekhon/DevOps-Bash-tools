#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
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

# Quick command line URL encoding

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ $# -gt 0 ]; then
    echo "$@"
else
    cat
fi |
if type -P perl &>/dev/null &&
   perl -MURI::ESCAPE -e '' &>/dev/null; then
 perl -MURI::Escape -ne 'chomp; print uri_escape($_) . "\n"'
elif type -p python3 &>/dev/null &&
     python3 -c 'from urllib.parse import quote_plus'; then
     python3 -c 'from urllib.parse import quote_plus; import sys; print(quote_plus(sys.stdin.read().rstrip("\n").rstrip("\r")))'
else
    echo "Neither Perl URI::Escape nor Python3 with UrlLib.Parse are available" >&2
    exit 1
fi
