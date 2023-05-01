#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-03-04 16:00:54 +0000 (Thu, 04 Mar 2021)
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
Lists Cloudflare Firewall Access Rules for a given Zone ID

In --verbose mode also also lists the filter expression at the end

Output:

<id>

Uses cloudflare_api.sh - see there for authentication API key details

See Also:

    cloudflare_zones.sh - to get the zone id argument
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<zone_id> [--verbose]"

help_usage "$@"

until [ $# -lt 1 ]; do
    case "$1" in
 -v|--verbose)  verbose=1
                ;;
           -*)  usage
                ;;
            *)  if [ -n "${zone_id:-}" ]; then
                    usage
                fi
                zone_id="$1"
                ;;
    esac
    shift || :
done

if [ -z "${zone_id:-}" ]; then
    usage "zone id not defined"
fi

"$srcdir/cloudflare_api.sh" "/zones/$zone_id/firewall/access_rules/rules" |
if [ -n "${verbose:-}" ]; then
    jq -r '.result[] | [.id, .mode, .notes, .configuration.target, .configuration.value] | @tsv'
else
    jq -r '.result[] | [.id, .mode, .notes] | @tsv'
fi
