#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-28 13:45:11 +0100 (Mon, 28 Mar 2022)
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
Find all Kubernetes API namespaced resource types and queries the current namespace for all of them

Useful to scan the current namespace for all resources since 'kubectl get all' only returns select API objects

Can set KUBECTL_GET_ALL_SEPARATOR environment variable, useful like this:

    KUBECTL_GET_ALL_SEPARATOR='---' ${0##*/} --all-namespaces -o yaml > dump.yaml

Useful to be able to scan live Kubernetes objects with file linting tools like Pluto to detect deprecated live objects on the cluster affecting your Kubernetes cluster upgrades


Requires Kubectl to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[-n <namespace> | -A | --all-namespaces] [ <kubectl_get_options> ]"

help_usage "$@"

#min_args 1 "$@"

non_gettable_resources="
bindings
localsubjectaccessreviews
localsubjectaccessreviews.authorization.k8s.io
selfsubjectaccessreviews.authorization.k8s.io
selfsubjectrulesreviews.authorization.k8s.io
subjectaccessreviews.authorization.k8s.io
tokenreviews.authentication.k8s.io
"

if [[ "$*" =~ -A|--all-namespaces ]]; then
    kubectl api-resources -o name
else
    kubectl api-resources --namespaced=true -o name
fi |
sort -fu |
while read -r resource; do
    # Error from server (MethodNotAllowed): the server does not allow this method on the requested resource
    for non_gettable_resource in $non_gettable_resources; do
        [ "$resource" = "$non_gettable_resource" ] && continue 2
    done
    if [ -n "${KUBECTL_GET_ALL_SEPARATOR:-}" ]; then
        echo "$KUBECTL_GET_ALL_SEPARATOR"
    fi
    echo "# $resource:" >&2
    kubectl get "$resource" "$@" 2>&1 |
    sed '/No resources found/d'
    echo
done
