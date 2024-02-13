#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-13 21:54:58 +0000 (Tue, 13 Feb 2024)
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
Deletes a DNS record in the given domain

Resolves the DNS record and then submits the request to delete the requested record

https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-delete-dns-record
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<domain> <hostname>"

help_usage "$@"

num_args 2 "$@"

domain="$1"
hostname="$2"

zone_id="$("$srcdir/cloudflare_zones.sh" |
           grep -E "^[[:alnum:]]+[[:space:]]+$domain$" |
           sed 's/[[:space:]].*$//' ||
           die "Failed to resolved zone id for domain '$domain' - is this the right domain name?")"

if [ -z "$zone_id" ]; then
    die "Zone ID is empty, check code"
fi

dns_record_id="$(
    "$srcdir/cloudflare_api.sh" "/zones/$zone_id/dns_records?per_page=50000" |
    jq -r '.result[] | [.id, .name] | @tsv' |
    grep -E "^[[:alnum:]]+[[:space:]]+$hostname" |
    head -n 1 |
    sed 's/[[:space:]].*$//' ||
    die "Failed to record DNS record '$hostname' in domain '$domain' - are the hostname and domain name correct?"
)"

"$srcdir/cloudflare_api.sh" "zones/$zone_id/dns_records/$dns_record_id" -X DELETE
