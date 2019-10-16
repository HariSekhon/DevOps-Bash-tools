#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-16 10:33:03 +0100 (Wed, 16 Oct 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

if [ "$(uname -s)" = Darwin ]; then
    echo "OS detected as Darwin, calling bootstrap_mac.sh"
    "$srcdir/bootstrap_mac.sh"
elif [ "$(uname -s)" = Linux ]; then
    echo "OS detected as Darwin, calling bootstrap_linux.sh"
    "$srcdir/bootstrap_linux.sh"
else
    echo "Only Mac & Linux are supported for conveniently bootstrapping all install scripts at this time"
    exit 1
fi
