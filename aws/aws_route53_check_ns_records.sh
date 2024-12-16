#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-06 12:58:19 +0100 (Wed, 06 Jul 2022)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Checks AWS Route 53 public hosted zones NS records are properly delegated in the public DNS hierarchy to all of the allocated AWS NS servers

Can specify one or more hosted zones space separated, otherwise will find and iterate all public hosted zones in the current AWS account

Helps test your AWS Route 53 setup and debug any imperfections in your NS delegation


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<public_hosted_zones_to_check>]"

help_usage "$@"

#min_args 1 "$@"

status=0

check_zone(){
    local id="$1"
    local zone="$2"
    local aws_ns_servers
    local aws_ns_status=0
    local public_ns_status=0
    timestamp "Checking domain '$zone'"
    aws_ns_servers="$(aws route53 get-hosted-zone --id "$id" | jq -r '.DelegationSet.NameServers[]')"
    #public_delegated_ns_servers="$(host -t NS "$zone" | awk '{print $4}')"
    public_delegated_ns_servers="$(dig "$zone" NS +short)"
    for aws_ns_server in $aws_ns_servers; do
        if grep -Fxq "$aws_ns_server." <<< "$public_delegated_ns_servers"; then
            timestamp "AWS NS server '$aws_ns_server' found"
        else
            timestamp "WARNING: AWS NS server '$aws_ns_server NOT FOUND in live public delegated NS servers for zone '$zone'"
            aws_ns_status=1
            status=1
        fi
    done
    for delegated_ns_server in $public_delegated_ns_servers; do
        if ! grep -Fxq "${delegated_ns_server%.}" <<< "$aws_ns_servers"; then
            timestamp "WARNING: ROGUE live delegated public NS server '$delegated_ns_server' found, not in list of AWS NS servers for zone '$zone'"
            public_ns_status=1
            status=1
        fi
    done
    if [ $aws_ns_status -eq 0 ]; then
        timestamp "AWS hosted zone '$zone' NS servers all accounted for in public DNS hierarchy delegation"
    fi
    if [ $public_ns_status -eq 0 ]; then
        timestamp "Domain '$zone' all public NS servers accounted for in AWS hosted zone"
    fi
    echo >&2
}

timestamp "Getting hosted zones list"
hosted_zones="$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | [.Id, .Name] | @tsv')"
echo >&2

if [ $# -gt 0 ]; then
    for zone in "$@"; do
        while read -r id name; do
            if [ "${zone%.}" = "${name%.}" ]; then
                check_zone "$id" "$name"
            fi
        done <<< "$hosted_zones"
    done
else
    while read -r id name; do
        check_zone "$id" "$name"
    done <<< "$hosted_zones"
fi

if [ $status -eq 0 ]; then
    timestamp "OK: All zones passed NS delegation validation"
else
    timestamp "ERROR: one or more zones failed NS delegation validation"
    exit 1
fi
