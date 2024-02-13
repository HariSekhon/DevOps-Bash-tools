#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-02 18:17:26 +0100 (Wed, 02 Sep 2020)
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
Lists all DNS records for a given Cloudflare zone

Resolves the domain name to a zone ID first and then submits the request to list the DNS records in that domain

https://api.cloudflare.com/#dns-records-for-a-zone-list-dns-records

Output format:

<dns_record>    <type>    <ttl>


Limitation: only lists the first 50,000 DNS records in a zone. Pagination code addition required if you have a zone larger than this
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<domain>"

help_usage "$@"

min_args 1 "$@"

domain="$1"

zone_id="$("$srcdir/cloudflare_zones.sh" |
           grep -E "^[[:alnum:]]+[[:space:]]+$domain$" |
           sed 's/[[:space:]].*$//' ||
           die "Failed to resolved zone id for domain '$domain' - is this the right domain name?")"

if [ -z "$zone_id" ]; then
    die "Zone ID is empty, check code"
fi

"$srcdir/cloudflare_api.sh" "/zones/$zone_id/dns_records?per_page=50000" |
jq -r '.result[] | [.name, .type, .ttl] | @tsv' |
column -t
