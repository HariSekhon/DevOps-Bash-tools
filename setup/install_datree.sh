#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-05-12 10:43:39 +0100 (Thu, 12 May 2022)
#
#  https://github.com/HariSekhon/bash-tools
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

curl https://get.datree.io | /bin/bash
echo

if [ -n "${DATREE_TOKEN:-}" ]; then
    echo "\$DATATREE_TOKEN found, configuring..."
    datree config set token "$DATREE_TOKEN"
fi
