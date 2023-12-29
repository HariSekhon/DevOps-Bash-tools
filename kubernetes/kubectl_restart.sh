#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-11 14:34:46 +0100 (Thu, 11 Aug 2022)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Restarts all deployments and statefulsets in the current or given namespace

Useful for example to restart all the ArgoCD components if it's stuck

Can optionally specify an ERE regex filter on the deployment or statefulset name


Requires kubectl to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace> <filter>]"

help_usage "$@"

namespace="${1:-}"
filter="${2:-}"

kube_config_isolate

if [ -n "$namespace" ]; then
    kube_namespace "$namespace"
fi

kubectl get deploy,sts -o name |
{ grep -E "$filter" || : ; } |
while read -r type_name; do
    # type_name is like deployment.apps/argocd-server or statefulset.apps/argocd-application-controller
    # and can be passed to kubectl as is
    kubectl rollout restart "$type_name"
done
