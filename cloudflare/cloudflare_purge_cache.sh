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
Purges EVERYTHING from the Cloudflare cache for the given zone id (which can be obtained from the adjacent cloudflare_zones.sh)

Requires CLOUDFLARE_EMAIL and CLOUDFLARE_TOKEN environment variables to be set

If CLOUDFLARE_ZONE_ID is set then you can omit the zone_id arg
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<zone_id>]"

help_usage "$@"

if [ -n "${CLOUDFLARE_ZONE_ID:-}" ]; then
    zone_id="$CLOUDFLARE_ZONE_ID"
else
    num_args 1 "$@"

    zone_id="$1"
fi

check_env_defined "CLOUDFLARE_EMAIL"
check_env_defined "CLOUDFLARE_TOKEN"

# curl auth will use these to send the token without putting it on the command line / logs
export CURL_AUTH_HEADER="X-Auth-Key:"
export TOKEN="$CLOUDFLARE_TOKEN"

        # don't use this, let curl_auth.sh do it more securely without leaving breadcrumbs on the local machine
        #-H "X-Auth-Key: $CLOUDFLARE_TOKEN" \

output="$(
    "$srcdir/../bin/curl_auth.sh" "https://api.cloudflare.com/client/v4/zones/$zone_id/purge_cache" \
        -sS -X POST \
        -H "Content-Type: application/json" \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        --data '{"purge_everything":true}' |
        jq
)"

echo "$output"

jq -e '.success == true' <<< "$output"
