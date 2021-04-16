#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-04-16 20:35:02 +0100 (Fri, 16 Apr 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Taints/untaints all nodes in the given GKE nodepool on the current cluster with your taint spec

See:

    kubectl taint nodes --help

for the taint spec
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<cluster_name>] <node_pool_name> <taint_spec>"

help_usage "$@"

min_args 1 "$@"

if [ $# -eq 3 ]; then
    export GCLOUD_CONTAINER_CLUSTER="$1"
    node_pool="$2"
    shift || :
    shift || :
elif [ $# -eq 2 ]; then
    node_pool="$1"
    shift || :
else
    usage
fi

kube_config_isolate

nodes="$(VERBOSE=1 "$srcdir/gke_nodepool_nodes.sh" "$node_pool")"

# want splitting
# shellcheck disable=SC2086
kubectl taint nodes $nodes "$@"
