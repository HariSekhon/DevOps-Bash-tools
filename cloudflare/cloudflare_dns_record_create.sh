#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-13 21:54:45 +0000 (Tue, 13 Feb 2024)
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
Creates a DNS record in the given domain

You must specify 'false' for the proxied argument or you will get a 400 error
as those addresses cannot be proxied by Cloudflare

Resolves the domain name to a zone ID first and then submits the request to create the requested record

https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-create-dns-record
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<domain> <hostname> <ip_or_content> <proxied_true_false> <record_type>"

help_usage "$@"

min_args 3 "$@"

domain="$1"
hostname="$2"
ip="$3"
proxied="${4:-true}"
record_type="${5:-A}"

if ! is_bool "$proxied"; then
    usage "proxied argument must be a boolean (true/false)"
fi

zone_id="$("$srcdir/cloudflare_zones.sh" |
           grep -E "^[[:alnum:]]+[[:space:]]+$domain$" |
           sed 's/[[:space:]].*$//' ||
           die "Failed to resolved zone id for domain '$domain' - is this the right domain name?")"

if [ -z "$zone_id" ]; then
    die "Zone ID is empty, check code"
fi

if [ -n "${CLOUDFLARE_DNS_RECORD_UPDATE:-}" ]; then
    request_type="PUT"
else
    request_type="POST"
fi

"$srcdir/cloudflare_api.sh" "zones/$zone_id/dns_records" \
                            -X "$request_type" \
                            -d "{
                                \"content\": \"$ip\",
                                \"name\": \"$hostname\",
                                \"proxied\": $proxied,
                                \"type\": \"$record_type\"
                            }"
