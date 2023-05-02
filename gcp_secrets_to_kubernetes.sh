#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-04 10:55:43 +0100 (Fri, 04 Sep 2020)
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
Loads given list of GCP Secret Manager secrets to the current Kubernetes cluster with the same name

If no secrets are specified, then finds all secrets in the current project with a label of kubernetes-cluster that
matches the current kubectl context's cluster and which do not have the label kubernetes-multi-part-secret set (as
these must be combined using gcp_secrets_to_kubernetes_multipart.sh instead)

For each secret, checks for a label called 'kubernetes-namespace', and if set, then creates the secret in that namespace,
otherwise loads to the current namespace. This can even be a comma separated list of namespaces and will create the secret in each one

Remember to execute this from the right GCP project configured to get the right secrets
and with the right Kubernetes context selected to load to the right cluster

To avoid concurrency race conditions between kubectl commands this script will isolate the current kubernetes context
environment in this script before beginning the load so that all secrets are loaded to the right cluster regardless of
any other naive kubernetes processes that might change the global kubectl context to point to a different cluster

See Also:

    Alternatives:

        Sealed Secrets   - https://github.com/bitnami-labs/sealed-secrets

        External Secrets - https://external-secrets.io/

            both of which are available in my Kubernetes repo - https://github.com/HariSekhon/Kubernetes-configs

    gke_kube_creds.sh - to create the Kubernetes cluster contexts in kubectl for your GKE clusters - you need to be using the correct kubectl context before running this script

    gcp_secrets_to_kubernetes_multipart.sh - for creating more complex multi-key-value secrets

    kubernetes_get_secret_values.sh - for checking what was auto-loaded into a given kubernetes secret
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<secret_name> <secret_name2> ...]"

help_usage "$@"

#min_args 1 "$@"

kube_config_isolate

# XXX: sets the GCP project for the duration of the script for consistency purposes (relying on gcloud config could lead to race conditions)
project="$(gcloud config list --format='get(core.project)' || :)"
export CLOUDSDK_CORE_PROJECT="${CLOUDSDK_CORE_PROJECT:-$project}"
not_blank "$CLOUDSDK_CORE_PROJECT" || die "ERROR: no project specified and \$CLOUDSDK_CORE_PROJECT / GCloud SDK config core.project value not set"

# there's no -o jsonpath / -o namespace / -o cluster as of Kubernetes 1.15 so have to just print columns
kubectl_context="$(kubectl config get-contexts "$(kubectl config current-context)" --no-headers)"
current_cluster="$(awk '{print $3}' <<< "$kubectl_context")"
current_namespace="$(awk '{print $5}' <<< "$kubectl_context")"
current_namespace="${current_namespace:-default}"

load_secret(){
    local secret="$1"
    local namespace
    namespaces="$(gcloud secrets describe "$secret" --format='get(labels.kubernetes-namespace)')"
    namespaces="${namespaces:-$current_namespace}"
    tr ',' '\n' <<< "$namespaces" |
    while read -r namespace; do
        [ -z "$namespace" ] && continue
        namespace="${NAMESPACE_OVERRIDE:-$namespace}"
        if kubectl get secret "$secret" -n "$namespace" &>/dev/null; then
            timestamp "kubernetes secret '$secret' already exists in namespace '$namespace', skipping creation..."
            return
        fi
        ## secrets created without a value are an odd use case but it has happened, so ignore and load blank value
        #latest_version="$(get_latest_secret_version "$secret" || :)"
        #if [ -n "$latest_version" ]; then
        #    value="$(gcloud secrets versions access "$latest_version" --secret="$secret")"
        #else
        #    timestamp "WARNING: no versions found for GCP secret '$secret', using blank secret value"
        #    value=""
        #fi
        value="$("$srcdir/gcp_secret_get.sh" "$secret")"
        timestamp "creating kubernetes secret '$secret' in namespace '$namespace'"
        # kubectl create secret automatically base64 encodes the $value
        # if you did this in yaml you'd have to base64 encode it yourself in the yaml
        #         could alternatively make this --from-literal="value=$value"
        kubectl create secret generic "$secret" --from-literal="$secret=$value" -n "$namespace"
    done
}

if [ $# -gt 0 ]; then
    for arg; do
        load_secret "$arg"
    done
else
    gcloud secrets list --format='value(name)' \
                        --filter="labels.kubernetes-cluster=$current_cluster \
                                  AND NOT \
                                  labels.kubernetes-multipart-secret ~ . \
                                  AND NOT \
                                  labels.kubernetes-multi-part-secret ~ ." |
    while read -r secret; do
        load_secret "$secret"
    done
fi
