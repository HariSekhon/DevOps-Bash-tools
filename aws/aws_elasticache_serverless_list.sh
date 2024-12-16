#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-16 12:03:31 +0700 (Mon, 16 Dec 2024)
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
Quick table of AWS ElastiCache useful fields:

Name, Engine, Status, Endpoint Address & Port, Description


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

aws elasticache describe-serverless-caches \
    --query 'ServerlessCaches[*].{
        "   Name":ServerlessCacheName,
        "  Engine":Engine,
        "  Status":Status,
        " Endpoint Address":Endpoint.Address,
        " Endpoint Port":Endpoint.Port,
        Description:Description
    }' \
    --output table
