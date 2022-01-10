#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-14 16:44:47 +0000 (Tue, 14 Dec 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://jfrog.com/getcli/

# https://www.jfrog.com/confluence/display/CLI/JFrog+CLI

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(dirname "${BASH_SOURCE[0]}")"

tmp="$(mktemp -d)"
cd "$tmp"

curl -fL https://getcli.jfrog.io | bash -s v2
echo
mv -iv jfrog ~/bin/jfrog
