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

# Quick command line URL decoding

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ $# -gt 0 ]; then
    echo "$@"
else
    cat
fi |
perl -MURI::Escape -ne 'chomp; print uri_unescape($_) . "\n"'
