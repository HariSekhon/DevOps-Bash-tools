#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-11 18:02:32 +0000 (Wed, 11 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

# shellcheck disable=SC2034
usage_description="
Cancels Codefresh delayed builds using the CodeFresh CLI

Requires Codefresh CLI to be installed and configured (see setup/setup_codefresh.sh)
"

[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

help_usage "$@"

codefresh get builds -s delayed -l 500 |
tail -n +2 |
sed 's/delayed.*//' |
while read -r id name; do
    echo "cancelling delayed build '$name' id '$id'"
    codefresh terminate "$id"
    echo
done
