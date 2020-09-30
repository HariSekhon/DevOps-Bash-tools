#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: HariSekhon/DevOps-Bash-tools
#
#  Author: Hari Sekhon
#  Date: 2020-10-01 00:19:22 +0100 (Thu, 01 Oct 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes all caches for the given Travis CI repo

Uses the adjacent travis_*.sh scripts
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<repo>"

help_usage "$@"

min_args 1 "$@"

repo="$1"
repo="${repo//\//%2F}"

timestamp "Deleting all caches for repo '$repo'"
"$srcdir/travis_api.sh" "/repo/$repo/caches" -X DELETE
