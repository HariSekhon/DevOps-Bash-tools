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
Loads a given list of GCP Secret Manager secrets to a single Kubernetes secret

Use the following command to see secrets you may want to combine and load to Kubernetes (eg. jwt-private-pem + jwt-public-pem):

    gcloud secrets list

Loads to the specified explicit Kubernetes namespace since multiple GCP secrets labels might conflict

See Also:

    Alternatives:

        Sealed Secrets   - https://github.com/bitnami-labs/sealed-secrets

        External Secrets - https://external-secrets.io/

            both of which are available in my Kubernetes repo - https://github.com/HariSekhon/Kubernetes-configs

    gcp_secrets_to_kubernetes.sh - for linear 1-to-1 secret auto-loading

    kubernetes_get_secret_values.sh - for checking what was auto-loaded into a given kubernetes secret
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<kubernetes_namespace> <kubernetes_secret_name> <gcp_secret_1> [<gcp_secret_2> ...]"

help_usage "$@"

min_args 3 "$@"

kube_config_isolate

# XXX: sets the GCP project for the duration of the script for consistency purposes (relying on gcloud config could lead to race conditions)
project="$(gcloud config list --format='get(core.project)' || :)"
export CLOUDSDK_CORE_PROJECT="${CLOUDSDK_CORE_PROJECT:-$project}"
not_blank "$CLOUDSDK_CORE_PROJECT" || die "ERROR: \$CLOUDSDK_CORE_PROJECT / GCloud SDK config core.project value not set"

namespace="$1"
kubernetes_secret="$2"
shift || :
shift || :

if kubectl get secret "$kubernetes_secret" -n "$namespace" &>/dev/null; then
    timestamp "Kubernetes secret '$kubernetes_secret' already exists in namespace '$namespace', skipping creation..."
    exit 0
fi

# auto base64 encodes the $value - you must base64 encode it yourself if putting it in via yaml
kubectl_cmd="kubectl create secret generic '$kubernetes_secret' -n '$namespace'"

for gcp_secret; do
    value="$("$srcdir/gcp_secret_get.sh" "$gcp_secret")"

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
