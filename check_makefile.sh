#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-01-17 14:07:17 +0000 (Sun, 17 Jan 2016)
#
#  https://github.com/harisekhon/nagios-plugins
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

grep '^[[:alpha:]]\+:' Makefile |
sort -u |
sed 's/:$//' |
while read target; do
    if ! make --warn-undefined-variables -n $target >/dev/null; then
        echo "Makefile validation FAILED"
        exit 1
    fi
done
echo "Makefile validation SUCCEEDED"
echo
