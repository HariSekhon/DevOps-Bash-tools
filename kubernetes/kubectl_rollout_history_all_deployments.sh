#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-14 11:42:58 +0100 (Wed, 14 Oct 2020)
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
Show the rollout history of all Kubernetes deployments in the current cluster context

Excludes kube-system

Useful to see if people have been using change-cause properly
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

kubectl get deploy -A -o custom-columns='name:.metadata.name,namespace:.metadata.namespace' |
tail -n +2 |
grep -v kube-system |
while read -r name namespace; do
    kubectl rollout history "deploy/$name" -n "$namespace"
done
