#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: all.knownips.circleci.com
#
#  Author: Hari Sekhon
#  Date: 2021-10-28 14:22:04 +0100 (Thu, 28 Oct 2021)
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
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries dnsjson.com for a given DNS record and prints the IP addresses

Defaults to a type A dns record if not given

Returns nothing if the DNS record is not found as dnsjson.com returns a blank result set in that case
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<dns_address> [<dns_record_type>]"

help_usage "$@"

min_args 1 "$@"

address="$1"
type="${2:-A}"

curl -sSL "https://dnsjson.com/$address/$type.json" |
jq -r '.results.records[]' |
sort -n
