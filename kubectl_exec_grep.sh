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
Kubectl exec's to the first pod name matching a grep extended regex

Execs /bin/sh because we can't be sure /bin/bash exists in a lot of containers

This is useful to quickly jump in to any pod in a namespace/deployment to debug a web farm etc.

First arg is a grep extended regular expression
Optional second arg if not a switch starting with '-' is assumed to be the container regex to exec in to
Subsequent args are passed straight to 'kubectl get pods' to set namespace or label filters

Example:

${0##*/} nginx

${0##*/} nginx -n prod

${0##*/} nginx -n prod -l app=nginx
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<pod_regex>] [<container_regex>] [<pod_filters>]"

help_usage "$@"

min_args 1 "$@"

pod_regex="$1"
shift || :

container_regex="."

if [ $# -gt 0 ]; then
    if ! [[ "$1" =~ ^- ]]; then
        container_regex="$1"
        shift || :
    fi
fi

pod="$(kubectl get pods --all-namespaces -o 'jsonpath={.items[*].metadata.name}' | tr ' ' '\n' | grep -E -m 1 "$pod_regex" || :)"

if [ -z "$pod" ]; then
    die "No matching pod found"
fi

# auto-determine namespace because specifying it is annoying
namespace="$(kubectl get pods --all-namespaces | grep -E "^[^[:space:]]+[[:space:]]+[^[:space:]]*${pod}" | awk '{print $1; exit}' || :)"

if [ -z "$namespace" ]; then
    die "failed to auto-determine namespace for pod '$pod'"
fi

# auto-determine container from regex if given or just take first container
container="$(kubectl get pods -n "$namespace" "$pod" -o 'jsonpath={.spec.containers[*].name}' | grep -m 1 "$container_regex" | awk '{print $1}' || :)"

if [ -z "$container" ]; then
    die "failed to get container name matching regex '$container_regex' for pod '$pod'"
fi

cmd="kubectl exec -ti --namespace \"$namespace\" \"$pod\" --container \"$container\" /bin/sh"
echo "$cmd"
eval "$cmd"
