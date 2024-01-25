#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-24 15:27:07 +0000 (Tue, 24 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# pending support ticket around permissions issue

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_description="Returns Shippable accounts for the given \$SHIPPABLE_TOKEN

Caveat: this API endpoint only works for paid accounts :-(

https://github.com/Shippable/support/issues/5068
"

help_usage "$@"

#curl -sSH 'Accept: application/json' 'https://api.shippable.com/projects?sortBy=createdAt&sortOrder=-1&ownerAccountIds=harisekhon'
"$srcdir/shippable_api.sh" '/accounts'
