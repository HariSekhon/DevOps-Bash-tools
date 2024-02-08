#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 12:10:23 +0000 (Fri, 11 Dec 2020)
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
Sets up a test AWS EKS cluster using eksctl with 3 worker nodes in a 1-4 node AutoScaling group

Takes about 20 minutes - uses CloudFormation to first create a stack with an EKS cluster management plane, then another stack with a node group,
and finally configures kubectl config with a context in the form of \$email@\$clustername.\$region.eksctl.io

Environment variables to configure:

EKS_CLUSTER - default: 'test'
EKS_VERSION - default: 1.21 - you should probably set this to the latest supported to avoid having to upgrade later
AWS_DEFAULT_REGION - default: 'eu-west-2'
AWS_ZONES - defaults to zones a, b and c in AWS_DEFAULT_REGION (eg. 'eu-west-2a,eu-west-2b,eu-west-2c') - may need to tweak them anyway to work around a lack of capacity in zones. Must match AWS_DEFAULT_REGION

See Also:

    eksctl.yaml - in HariSekhon/Templates repo
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<cluster_name> <kubernetes_version> <region> <aws_zones>]"

help_usage "$@"

#min_args 1 "$@"

if ! command -v eksctl &>/dev/null; then
    "$srcdir/../install/install_eksctl.sh"
    echo
fi

EKS_CLUSTER="${1:-${EKS_CLUSTER:-test}}"
EKS_VERSION="${2:-${EKS_VERSION:-1.21}}"
# set a default here as needed to infer zones if not set
AWS_DEFAULT_REGION="${3:-${AWS_DEFAULT_REGION:-eu-west2}}"
AWS_ZONES="${4:-${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}b,${AWS_DEFAULT_REGION}c}"

# shellcheck disable=SC2013
for zone in ${AWS_ZONES//,/ }; do
    region="${zone::${#zone}-1}"
    if [ "$region" != "$AWS_DEFAULT_REGION" ]; then
        usage "invalid zone '$zone' given, must match region '$AWS_DEFAULT_REGION'"
    fi
done

# cluster will be called "eksctl-$name-cluster", in this case "eksctl-test-cluster"
timestamp "Creating AWS EKS cluster via eksctl"
eksctl create cluster --name "$EKS_CLUSTER" \
                      --version "$EKS_VERSION" \
                      --region "$AWS_DEFAULT_REGION" \
                      --zones "$AWS_ZONES" \
                      --managed \
                      --nodegroup-name standard-workers \
                        --node-type t3.micro \
                        --nodes 3 \
                        --nodes-min 1 \
                        --nodes-max 4
