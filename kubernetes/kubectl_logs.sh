#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-11 14:44:05 +0100 (Thu, 11 Aug 2022)
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
Tails logs from several pods a the same time in the current or given namespace

Useful for debugging and quickly checking which components in a distributed app are having issues

Can optionally specify an ERE regex filter on the pod name

Requires kubectl to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace> <filter>]"

namespace="${1:-}"
filter="${2:-}"

kube_config_isolate

if [ -n "$namespace" ]; then
    kube_namespace "$namespace"
fi

# kill all child processes by session id on cleanup, which is less likely to be changed than parent id
if is_mac; then
    # want late evaluation
    # shellcheck disable=SC2016
    trap_cmd 'kill $(ps -g $$ -o pid=) 2>/dev/null'
else
    # shellcheck disable=SC2016
    trap_cmd 'kill $(ps -s $$ -o pid=) 2>/dev/null'
fi

# avoiding subshell pipe into while loop otherwise 'wait' below won't wait
while read -r pod_name; do
    # pod_name is like pod/argocd-server-7558b87667-4fmx7
    # and can be passed to kubectl as is
    kubectl logs --tail 10 -f "$pod_name" --all-containers=true &
done < <( kubectl get pods -o name | grep -E "$filter" || : )

wait
