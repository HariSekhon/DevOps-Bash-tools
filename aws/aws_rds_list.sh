#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-11 04:49:35 +0300 (Fri, 11 Oct 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
List RDS instances with select fields - Name, Status, Engine, AZ, Instance Type, Storage, Endpoint DNS FQDN Address

$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<region>]"

help_usage "$@"

max_args 1 "$@"

if [ $# -gt 0 ]; then
    export AWS_DEFAULT_REGION="$1"
fi

aws rds describe-db-instances \
    --query "DBInstances[*].[DBInstanceIdentifier, DBInstanceStatus, Engine, AvailabilityZone, DBInstanceClass, AllocatedStorage, Endpoint.Address]" \
    --output table
