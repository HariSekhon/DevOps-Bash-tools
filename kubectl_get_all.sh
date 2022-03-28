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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Find all Kubernetes API namespaced resource types and queries the current namespace for all of them

Useful to scan the current namespace for all resources since 'kubectl get all' only returns select API objects

Requires Kubectl to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="´[-n <namespace>]"

help_usage "$@"

#min_args 1 "$@"

kubectl api-resources |
grep '[[:space:]]true[[:space:]]' |
awk '{print $1}' |
while read -r resource; do
    # Error from server (MethodNotAllowed): the server does not allow this method on the requested resource
    [ "$resource" = "bindings" ] && continue
    [ "$resource" = "localsubjectaccessreviews" ] && continue
    echo "$resource:"
    kubectl get "$resource" "$@" 2>&1 |
    sed '/No resources found/d'
    echo
done
