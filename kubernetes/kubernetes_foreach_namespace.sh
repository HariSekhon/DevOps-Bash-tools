#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: bash -c 'echo -n "kubectl context: "; kubectl config get-contexts | awk "/^\*/{print \$5\" \"\$3}"; echo "namespace: {namespace}"'
#
#  Author: Hari Sekhon
#  Date: 2020-09-08 19:20:40 +0100 (Tue, 08 Sep 2020)
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
Run a command against each Kubernetes namespace on the current cluster / kubectl context

Can chain with kubernetes_foreach_context.sh

This is powerful so use carefully!

WARNING: do not run any command reading from standard input, otherwise it will consume the namespace names and exit after the first iteration

All arguments become the command template

Replaces {namespace} if present in the command template with the namespace in each iteration, but often this isn't necessary to specify explicitly given the kubectl context's namespace is set within each iteration for convenience running short commands local to the namespace

eg.
    ${0##*/} gcp_secrets_to_kubernetes.sh


Requires 'kubectl' to be configured and available in \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

kube_config_isolate

current_context="$(kubectl config current-context)"

# there is no -o jsonpath/namespace so must just get column
# don't need to store this any more as we now switch the KUBECONFIG which is only used for the lifetime of this script
#original_namespace="$(kubectl config get-contexts "$current_context" --no-headers | awk '{print $5}')"

set_namespace(){
    local namespace="$1"
    kubectl config set-context "$current_context" --namespace "$namespace"
}

#kubectl get namespaces -o name | sed 's,namespace/,,' |
kubectl get namespaces -o 'jsonpath={range .items[*]}{.metadata.name}{"\n"}' |
while read -r namespace; do
    #if [[ "$context" =~ kube-system ]]; then
    #    echo "Skipping context '$context'..."
    #    echo
    #    continue
    #fi
    echo "# ============================================================================ #" >&2
    echo "# Kubernetes namespace = $namespace, content = $current_context" >&2
    echo "# ============================================================================ #" >&2
    # shellcheck disable=SC2064  # want interpolation now
    # XXX: no longer reset because we isolate the environment above via redirecting KUBECONFIG and simply let it expire at the end of this script
    #trap "echo; echo 'Reverting context to original namespace: $original_namespace' ; set_namespace '$original_namespace'" EXIT
    set_namespace "$namespace"
    cmd=("$@")
    cmd=("${cmd[@]//\{namespace\}/$namespace}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo
done
