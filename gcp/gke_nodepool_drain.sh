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
Drains all Kubernetes nodes from a given GKE cluster's nodepool

Useful to decommission an entire nodepool to delete or recreate it (eg. with different taints)

You must have a second node pool with sufficient capacity / autoscaling max nodes to be able to accommodate the evicted pods

- finds instance groups in a node pool
- finds nodes in each instance group
- disables autoscaling for the node pool (to prevent booting new nodes to migrate pods to)
- cordons all nodes (to prevent pod migrations to other nodes in the same pool)
- drains pods from each node in sequence

Requires:

    - GCloud SDK to be installed and configured
      - requires core/project and compute/region to be set in your gcloud config
        or else environment variables CLOUDSDK_CORE_PROJECT and CLOUDSDK_COMPUTE_REGION
    - uses adjacent scripts:
      - gke_nodepool_nodes2.sh - lists all nodes in the given nodepool
      - gke_kubectl.sh - for safe kubectl with isolated context

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

nodes="$(VERBOSE=1 "$srcdir/gke_nodepool_nodes2.sh" "$node_pool")"

echo >&2
timestamp "disabling autoscaling for node pool '$node_pool'"
gcloud container node-pools update --no-enable-autoscaling "$node_pool"

echo >&2
timestamp "cordoning nodes:"
for node in $nodes; do
    #timestamp "cordoning node '$node'"
    "$srcdir/gke_kubectl.sh" cordon "$node"
done

force=""
if [ "${FORCE:-1}" ]; then
    force="--force"
fi

for node in $nodes; do
    echo >&2
    timestamp "draining node '$node'"
    "$srcdir/gke_kubectl.sh" drain "$node" $force --ignore-daemonsets  # &  # could parallelize this - respects pod disruption budgets
done
