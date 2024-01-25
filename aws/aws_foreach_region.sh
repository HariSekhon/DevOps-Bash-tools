#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: 'echo region is {region}'
#
#  Author: Hari Sekhon
#  Date: 2021-07-19 14:59:58 +0100 (Mon, 19 Jul 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
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
Run a command against each AWS region enabled for the current account

You may want to use this to run an AWS CLI command against all regions to find resources or perform scripting across regions

This is powerful so use carefully!

WARNING: do not run any command reading from standard input, otherwise it will consume the region names and exit after the first iteration

Requires AWS CLI to be installed and configured and 'aws' to be in the \$PATH

All arguments become the command template

The following command template tokens are replaced in each iteration:

AWS Region:     {region}

If \$AWS_ALL_REGIONS is defined and not empty then iterates all regions, even those not enabled for the current account


Examples:

    ${0##*/} 'echo AWS region is {region}'

    AWS_ALL_REGIONS=1 ${0##*/} 'echo AWS region is {region}'

Find EC2 instances across regions:

    ${0##*/} aws ec2 describe-instances

    ${0##*/} 'aws ec2 describe-instances | jq -r \".Reservations | length\"'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

export AWS_DEFAULT_OUTPUT=json

# --all-regions iterates all regions whether or not they are enabled for the current account
if [ -n "${AWS_ALL_REGIONS:-}" ]; then
    aws ec2 describe-regions --all-regions
else
    aws ec2 describe-regions
fi |
jq -r '.Regions[] | .RegionName' |
while read -r region; do
    echo "# ============================================================================ #" >&2
    echo "# AWS region = $region" >&2
    echo "# ============================================================================ #" >&2
    export AWS_DEFAULT_REGION="$region"
    cmd=("$@")
    cmd=("${cmd[@]//\{region\}/$region}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
    echo >&2
done
