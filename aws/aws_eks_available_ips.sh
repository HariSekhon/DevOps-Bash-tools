#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-01 02:37:24 +0700 (Wed, 01 Jan 2025)
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
Lists the number of available IP addresses in the EKS subnets for the given cluster (5 required for an EKS upgrade)

Requires either first arg of the EKS cluster name, or the environment variable \$EKS_CLUSTER

If neither are given, checks clusters and if only one is found in account, uses that

Output should look like this:

---------------------------------------------------
|                 DescribeSubnets                 |
+---------------------------+--------------+------+
|  subnet-067fa8ee8476abbd6 |  eu-west-1a  |  119 |
|  subnet-0056f7403b17d2b43 |  eu-west-1a  |  121 |
|  subnet-09586f8fb3addbc8c |  eu-west-1b  |  109 |
|  subnet-047f3d276a22c6bce |  eu-west-1b  |  118 |
+---------------------------+--------------+------+


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<cluster_name>]"

help_usage "$@"

max_args 1 "$@"

cluster="${1:-${EKS_CLUSTER:-}}"

if is_blank "$cluster"; then
    cluster="$(aws_eks_cluster_if_only_one)"
    if ! is_blank "$cluster"; then
        timestamp "No cluster specified but only one found in this account, using that: $cluster"
    else
        usage "Need to define cluster name"
    fi
fi

timestamp "Getting subnets for EKS cluster: $cluster"
subnet_ids="$(
    aws eks describe-cluster --name "$cluster" \
        --query 'cluster.resourcesVpcConfig.subnetIds' \
        --output text
)"
echo >&2

timestamp "Getting subnets and their AvailableIpAddressCount"
echo >&2
# needs splitting, quoting them with strings or comma separators both break in AWS CLI
# shellcheck disable=SC2086
aws ec2 describe-subnets --subnet-ids $subnet_ids \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,AvailableIpAddressCount]' \
  --output table

# output should look like this
#
#----------------------------------------------------
#|                  DescribeSubnets                 |
#+---------------------------+--------------+-------+
#|  subnet-067fa8ee8476abbd6 |  us-east-1a  |  8184 |
#|  subnet-0056f7403b17d2b43 |  us-east-1b  |  8153 |
#|  subnet-09586f8fb3addbc8c |  us-east-1a  |  8120 |
#|  subnet-047f3d276a22c6bce |  us-east-1b  |  8184 |
#+---------------------------+--------------+-------+
