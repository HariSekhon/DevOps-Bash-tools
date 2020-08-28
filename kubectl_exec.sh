#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-28 11:06:23 +0100 (Fri, 28 Aug 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Kubectl exec's to the first pod in the current or given namespace

Execs /bin/sh because we can't be sure /bin/bash exists in a lot of containers

This is useful to quickly jump in to any pod in a namespace/deployment to debug a web farm etc.

Optional args include namespace for the first arg unless it starts with the dash in which case it's assumed to be a regular filter switch, and any remaining args are passed straight to 'kubectl get pods' to be used as filters, eg. -l app=nginx

Example:

${0##*/} prod-namespace -l app=nginx

${0##*/} prod-namespace sidecar-container -l app=nginx
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace>] [<container>] [<pod_filters>]"

help_usage "$@"

#pod_min_args 1 "$@"

namespace=""
container=""

if [ $# -gt 0 ]; then
    if ! [[ "$1" =~ ^- ]]; then
        namespace="$1"
        shift
    fi
fi
if [ $# -gt 0 ]; then
    if ! [[ "$1" =~ ^- ]]; then
        container="$1"
        shift
    fi
fi

namespace_opt=""
if [ -n "$namespace" ]; then
    namespace_opt="-n $namespace"
fi

container_opt=""
if [ -n "$container" ]; then
    container_opt="-c $container"
fi

# want splitting and cannot quote because would pass breaking whitespace args
# shellcheck disable=SC2086,SC2090
pod="$(kubectl get pods $namespace_opt "$@" -o 'jsonpath={.items[0].metadata.name}')"

if [ -n "$container_opt" ]; then
    timestamp "Exec'ing to pod '$pod' container '$container'"
else
    timestamp "Exec'ing to pod '$pod'"
fi

# want splitting and cannot quote because would pass breaking whitespace args
# shellcheck disable=SC2086,SC2090
# # want splitting and cannot quote because would pass breaking whitespace args
kubectl exec -it $namespace_opt "$pod" $container_opt /bin/sh
