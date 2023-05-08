#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-24 13:14:16 +0100 (Mon, 24 Aug 2020)
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
Gets the average latency per hour of the day, averaged over the last week, for all Pingdom checks via the Pingdom API

Output format - quoted CSV:

<hour_of_day>,<average_latency_in_ms>

For TSV format, set TSV=1 environment variable


\$PINGDOM_TOKEN must be defined in the environment for authentication

See adjacent pingdom_api.sh for more details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

"$srcdir/pingdom_foreach_check.sh" "$srcdir/pingdom_check_latency_by_hour.sh" "{id}"
