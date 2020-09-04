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
Loads given list of GCP Secret Manager secrets to a single Kubernetes secret

Use the following command to see secrets you may want to combine and load to Kubernetes (eg. jwt-private-pem + jwt-public-pem):

    gcloud secrets list

Loads to the current Kubernetes namespace since there is no namespace information in Google Secret Manager, so you may
want to switch to the right namespace first (see kcd in .bash.d/kubernetes for a convenient way to persist this in your session)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<kubernetes_secret_name> <gcp_secret_1> [<gcp_secret_2> ...]"

help_usage "$@"

min_args 2 "$@"

get_latest_version(){
    local secret="$1"
    gcloud secrets versions list "$secret" --filter='state = enabled' --format='value(name)' |
    sort -k1nr |
    head -n1
}

kubernetes_secret="$1"
shift || :

if kubectl get secret "$kubernetes_secret" &>/dev/null; then
    echo "WARNING: kubernetes secret '$kubernetes_secret' already exists, skipping creation..." >&2
    exit 1
fi

# auto base64 encodes the $value - you must base64 encode it yourself if putting it in via yaml
kubectl_cmd="kubectl create secret generic '$kubernetes_secret' "

for gcp_secret; do
    latest_version="$(get_latest_version "$gcp_secret")"
    value="$(gcloud secrets versions access "$latest_version" --secret="$gcp_secret")"
    # this is all really annoying because there is no right answer to this convention
    # because GCP Secret Manager won't let you use dots so mangle jwt-private-pem => jwt-private.pem
    #gcp_secret="$(perl -pe 's/[_-]pem$/.pem/' <<< "$gcp_secret")"
    # actually apps expect just private.pem and public.pem in the secret mounted directory
    if [[ "$gcp_secret" =~ -private-pem$ ]]; then
        gcp_secret="private.pem"
    elif [[ "$gcp_secret" =~ -public-pem$ ]]; then
        gcp_secret="public.pem"
    fi
    kubectl_cmd+=" --from-literal='$gcp_secret=$value'"
done

eval "$kubectl_cmd"
