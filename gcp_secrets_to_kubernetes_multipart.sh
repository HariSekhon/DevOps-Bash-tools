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
Loads a given list of GCP Secret Manager secrets to a single Kubernetes secret

Use the following command to see secrets you may want to combine and load to Kubernetes (eg. jwt-private-pem + jwt-public-pem):

    gcloud secrets list

Loads to the specified explicit Kubernetes namespace since multiple GCP secrets labels might conflict

See Also:

    gcp_secrets_to_kubernetes.sh - for linear 1-to-1 secret auto-loading

    kubernetes_get_secret_values.sh - for checking what was auto-loaded into a given kubernetes secret
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<kubernetes_secret_name> <kubernetes_namespace> <gcp_secret_1> [<gcp_secret_2> ...]"

help_usage "$@"

min_args 3 "$@"

# fix kube cluster to protect consistency against k8s race conditions
kubeconfig="/tmp/.kube/config.${EUID:-$UID}.$$"
mkdir -p "$(dirname "$kubeconfig")"
cp -f "${KUBECONFIG:-$HOME/.kube/config}" "$kubeconfig"
export KUBECONFIG="$kubeconfig"

# XXX: fix the GCP project for the duration of the script for consistency
project="$(gcloud config list --format='get(core.project)')"
not_blank "$project" || die "ERROR: GCloud SDK core.project value not set"
export CLOUDSDK_CORE_PROJECT="$project"

get_latest_version(){
    local secret="$1"
    gcloud secrets versions list "$secret" --filter='state = enabled' --format='value(name)' |
    sort -k1nr |
    head -n1
}

kubernetes_secret="$1"
namespace="$2"
shift || :
shift || :

if kubectl get secret "$kubernetes_secret" -n "$namespace" &>/dev/null; then
    timestamp "kubernetes secret '$kubernetes_secret' already exists in namespace '$namespace', skipping creation..." >&2
    exit 1
fi

# auto base64 encodes the $value - you must base64 encode it yourself if putting it in via yaml
kubectl_cmd="kubectl create secret generic '$kubernetes_secret' -n '$namespace'"

for gcp_secret; do
    latest_secret_version="$(get_latest_version "$gcp_secret")"

    value="$(gcloud secrets versions access "$latest_secret_version" --secret="$gcp_secret")"

    # this is all really annoying because there is no right answer to this convention
    # because GCP Secret Manager won't let you use dots so mangle jwt-private-pem => jwt-private.pem
    #gcp_secret="$(perl -pe 's/[_-]pem$/.pem/' <<< "$gcp_secret")"
    # actually apps expect just private.pem and public.pem in the secret mounted directory
    if [[ "$gcp_secret" =~ -private-pem$ ]]; then
        key="private.pem"
    elif [[ "$gcp_secret" =~ -public-pem$ ]]; then
        key="public.pem"
    else
        key="$gcp_secret"
    fi

    kubectl_cmd+=" --from-literal='$key=$value'"
done

timestamp "creating kubernetes secret '$kubernetes_secret' in namespace '$namespace' from GCP secrets: $*"
eval "$kubectl_cmd"
