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

Resolves the domain name to a zone ID first and then submits the request to create the requested record

https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-patch-dns-record

Uses adjacent cloudflare_dns_record_create.sh

You might get this error:

"'    {"success":false,"errors":[{"code":10000,"message":"PUT method not allowed for the api_token authentication scheme"}]}
'

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<domain> <hostname> <ip_or_content> <proxied_true_false> <record_type>"

help_usage "$@"

min_args 3 "$@"

export CLOUDFLARE_DNS_RECORD_UPDATE=1

"$srcdir/cloudflare_dns_record_create.sh" "$@"
