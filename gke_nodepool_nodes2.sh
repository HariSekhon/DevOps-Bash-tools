#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-04-16 17:44:30 +0100 (Fri, 16 Apr 2021)
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
Lists all Kubernetes nodes in a given GKE cluster's nodepool

- finds instance groups in a node pool
- finds nodes in each instance group

Requires:

    - GCloud SDK to be installed and configured
      - requires core/project and compute/region to be set in your gcloud config
        or else environment variables CLOUDSDK_CORE_PROJECT and CLOUDSDK_COMPUTE_REGION

If gcloud config container/cluster or CLOUDSDK_CONTAINER_CLUSTER are set then you don't have to specify the cluster name
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<cluster_name>] <node_pool_name>"

help_usage "$@"

min_args 1 "$@"

if [ $# -eq 2 ]; then
    export GCLOUD_CONTAINER_CLUSTER="$1"
    node_pool="$2"
elif [ $# -eq 1 ]; then
    node_pool="$1"
else
    usage
fi

if [ -n "${VERBOSE:-}" ]; then
    timestamp "finding instance groups in node pool '$node_pool'"
fi
instance_groups="$(
    gcloud container node-pools describe "$node_pool" --format=json |
    jq -r '.instanceGroupUrls[] | sub("^.*/"; "")'
)"

if [ -n "${VERBOSE:-}" ]; then
    echo >&2
fi
for instance_group in $instance_groups; do
    if [ -n "${VERBOSE:-}" ]; then
        #timestamp "finding zone of instance group '$instance_group'"
        timestamp "finding nodes in instance group '$instance_group'"
    fi
    zone="$(gcloud compute instance-groups list --filter="name=$instance_group" --format='get(zone)' | sed 's|^.*/||')"
    gcloud compute instance-groups list-instances "$instance_group" --zone "$zone" --format='value(NAME)'  # doesn't find it without zone, and NAME must be capitalized too
done
