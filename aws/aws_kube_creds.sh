#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 00:36:09 +0000 (Fri, 11 Dec 2020)
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
Generates kubectl credentials and contexts for all AWS EKS clusters in the current AWS region

This is fast way to get set up in new environments, or even just add any new EKS clusters to your existing \$HOME/.kube/config

Requires AWS CLI to be set up and configured, as well as jq

WARNING: AWS CLI switches your kubectl context to the last cluster you get credentials for. This can lead to race conditions between other kubectl scripts if they have not forked and isolated their \$KUBECONFIG. Do not run this while other naive kubectl commands and scripts are running otherwise those non-isolated commands may fire against the wrong kubernetes cluster. See kubectl.sh for more info

Can supply arguments to be passed to AWS CLI to set things like region eg.

    ${0##*/} --region eu-west-2


$usage_aws_cli_jq_required


See also:

    kubectl.sh             - isolates kube config to fix kubectl commands to the given cluster to prevent race conditions from applying kubectl changes to the wrong cluster
    aws_kubectl.sh         - same as above but also gets the credential
    gke_kube_creds.sh      - same as this script but for GCP GKE clusters
    rancher_kube_creds.sh  - same as this script but for Rancher Kubernetes clusters
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_cli_options>]"

help_usage "$@"

export AWS_DEFAULT_OUTPUT=json

aws eks list-clusters "$@" |
jq -r '.clusters[]' |
while read -r cluster; do
    echo "Getting AWS EKS credentials for cluster '$cluster':"
    aws eks update-kubeconfig --name "$cluster" "$@"
    echo
done
