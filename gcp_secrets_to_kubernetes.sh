#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-04 10:55:43 +0100 (Fri, 04 Sep 2020)
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
Loads given list of GCP Secret Manager secrets to the current Kubernetes cluster with the same name

If no secrets are specified, then finds all secrets in the current project with a label of kubernetes-cluster that
matches the current kubectl context's cluster and which do not have the label kubernetes-multi-part-secret set (as
these must be combined using gcp_secrets_to_kubernetes_multipart.sh instead)

For each secret, checks for a label called 'kubernetes-namespace', and if set, then creates the secret in that namespace,
otherwise loads to the current namespace. This can even be a comma separated list of namespace and will create the secret in each one

Remember to execute this from the right GCP project configured to get the right secrets
and with the right Kubernetes context selected to load to the right cluster

To avoid concurrency race conditions between kubectl commands this script will isolate the current kubernetes context
environment in this script before beginning the load so that all secrets are loaded to the right cluster regardless of
any other naive kubernetes processes that might change the global kubectl context to point to a different cluster

See Also:

    gcp_secrets_to_kubernetes_multipart.sh - for create more complex compound secrets

    kubernetes_get_secret_values.sh - for checking what was auto-loaded into a given kubernetes secret
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<secret_name> <secret_name2> ...]"

help_usage "$@"

#min_args 1 "$@"

# XXX: fix kube cluster to protect consistency against k8s race conditions
kubeconfig="/tmp/.kube/config.${EUID:-$UID}.$$"
mkdir -p "$(dirname "$kubeconfig")"
cp -f "${KUBECONFIG:-$HOME/.kube/config}" "$kubeconfig"
export KUBECONFIG="$kubeconfig"

# XXX: fix the GCP project for the duration of the script for consistency
project="$(gcloud config list --format='get(core.project)')"
not_blank "$project" || die "ERROR: GCloud SDK core.project value not set"
export CLOUDSDK_CORE_PROJECT="$project"

# there's no -o jsonpath / -o namespace / -o cluster as of Kubernetes 1.15 so have to just print columns
kubectl_context="$(kubectl config get-contexts "$(kubectl config current-context)" --no-headers)"
current_cluster="$(awk '{print $3}' <<< "$kubectl_context")"
current_namespace="$(awk '{print $5}' <<< "$kubectl_context")"
current_namespace="${current_namespace:-default}"

get_latest_secret_version(){
    local secret="$1"
    gcloud secrets versions list "$secret" --filter='state = enabled' --format='value(name)' |
    sort -k1nr |
    head -n1
}

load_secret(){
    local secret="$1"
    local namespace
    namespaces="$(gcloud secrets describe "$secret" --format='get(labels.kubernetes-namespace)')"
    namespaces="${namespaces:-$current_namespace}"
    while read -r namespace; do
        [ -z "$namespace" ] && continue
        if kubectl get secret "$secret" -n "$namespace" &>/dev/null; then
            timestamp "kubernetes secret '$secret' already exists in namespace '$namespace', skipping creation..."
            return
        fi
        latest_version="$(get_latest_secret_version "$secret")"
        value="$(gcloud secrets versions access "$latest_version" --secret="$secret")"
        timestamp "creating kubernetes secret '$secret' in namespace '$namespace'"
        # kubectl create secret automatically base64 encodes the $value
        # if you did this in yaml you'd have to base64 encode it yourself in the yaml
        #         could alternatively make this --from-literal="value=$value"
        kubectl create secret generic "$secret" --from-literal="$secret=$value" -n "$namespace"
    done < <(tr ',' '\n' <<< "$namespaces")
}

if [ $# -gt 0 ]; then
    for arg; do
        load_secret "$arg"
    done
else
    while read -r secret; do
        load_secret "$secret"
    done < <(gcloud secrets list --format='value(name)' \
                                 --filter="labels.kubernetes-cluster=$current_cluster \
                                           AND NOT \
                                           labels.kubernetes-multi-part-secret ~ .")
fi
