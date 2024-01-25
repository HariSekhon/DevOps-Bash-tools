#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-09 11:37:14 +0100 (Wed, 09 Sep 2020)
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
Lists Kubernetes container images running on the cluster along with their deployments, statefulsets of daemonsets that they belong to

Useful to find which deployment, stateful or daemonset to upgrade such hunting down an images such as when the kubernetes project deprecated the k8s.gcr.io registry in favour of registry.k8s.io

Output:

<api>    <kind>    <namespace>    <name>    <image:tag>

Requires kubectl to be in \$PATH and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

kubectl get deploy,sts,ds --all-namespaces -o json |
# jq trick {} expands out the sub-array elements
jq -r '
    .items[] |
        {
            "api":.apiVersion,
            "kind": .kind,
            "namespace": .metadata.namespace,
            "name": .metadata.name,
            # jq trick having a list here causes the rest of this map to be duplicated one per list item
            "images": [.spec.template.spec.initContainers[]?.image, .spec.template.spec.containers[]?.image] | flatten[]
        } |
        [
            .api,
            .kind,
            .namespace,
            .name,
            .images
        ] | @tsv
' |
sort -k3 -u |
column -t
