#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: bash -c 'echo -n "kubectl context: "; kubectl config current-context; echo "context: {context}"'
#
#  Author: Hari Sekhon
#  Date: 2020-08-26 16:18:30 +0100 (Wed, 26 Aug 2020)
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
Run a command against each configured Kubernetes kubectl context (cluster)

Can chain with kubernetes_foreach_namespace.sh

This is powerful so use carefully!

WARNING: do not run any command reading from standard input, otherwise it will consume the context names and exit after the first iteration

All arguments become the command template

Replaces {context} if present in the command template with the current kubectl context name in each iteration, but often this isn't necessary to specify explicitly given the kubectl context is set within each iteration for each context for convenience running short commands local to the context

eg.
    ${0##*/} kubectl get pods

Since lab contexts like Docker Desktop, Minikube etc are often offline and likely to hang, they are skipped. Deleted GKE clusters you'll need to remove from your kubeconfig yourself before calling this

See Also: gke_kube_creds.sh to auto-create all your contexts for all clusters on Google Kubernetes Engine!


Requires 'kubectl' to be configured and available in \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

kube_config_isolate

# don't need to store this any more as we now switch the KUBECONFIG which is only used for the lifetime of this script
#original_context="$(kubectl config current-context)"

kubectl config get-contexts -o name |
while read -r context; do
    if [[ "$context" =~ docker|minikube|minishift ]]; then
        echo "Skipping context '$context'..."
        echo
        continue
    fi
    echo "# ============================================================================ #" >&2
    echo "# Kubernetes context = $context" >&2
    echo "# ============================================================================ #" >&2
    # shellcheck disable=SC2064  # want interpolation now
    # XXX: no longer reset because we isolate the environment above via redirecting KUBECONFIG and simply let it expire at the end of this script
    #trap "echo; echo 'Reverting to original context:' ; kubectl config use-context '$original_context'" EXIT
    kubectl config use-context "$context"
    cmd=("$@")
    cmd=("${cmd[@]//\{context\}/$context}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo
done
