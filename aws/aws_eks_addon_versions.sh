#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-01 01:52:09 +0700 (Wed, 01 Jan 2025)
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
Lists the EKS addon versions available for the given cluster by checking its version before checking addons

Requires either first arg of the EKS cluster name, or the environment variable \$EKS_CLUSTER

If neither are given, checks clusters and if only one is found in account, uses that


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

timestamp "Getting cluster version for: $cluster"
cluster_version="$(aws eks describe-cluster --name "$cluster" --query "cluster.version" --output text)"
timestamp "Cluster version: $cluster_version"

aws eks describe-addon-versions \
    --kubernetes-version "$cluster_version" \
    --addon-name vpc-cni \
    --query 'addons[].addonVersions[].{Version: addonVersion, Defaultversion: compatibilities[0].defaultVersion}' \
    --output table
