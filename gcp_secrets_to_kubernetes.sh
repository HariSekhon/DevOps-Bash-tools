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

If no secrets are specified, then finds all secrets in the current project with labels of kubernetes-namespace that match the current kubectl context's namespace

Loads to the current Kubernetes namespace since there is no namespace information in Google Secret Manager, so you may
want to switch to the right namespace first (see kcd in .bash.d/kubernetes for a convenient way to persist this in your session)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<secret_name> <secret_name2> ...]"

help_usage "$@"

#min_args 1 "$@"

get_latest_version(){
    local secret="$1"
    gcloud secrets versions list "$secret" --filter='state = enabled' --format='value(name)' |
    sort -k1nr |
    head -n1
}

load_secret(){
    local secret="$1"
    if kubectl get secret "$secret" &>/dev/null; then
        echo "WARNING: secret '$secret' already exists, skipping..." >&2
        return
    fi
    latest_version="$(get_latest_version "$secret")"
    value="$(gcloud secrets versions access "$latest_version" --secret="$secret")"
    # auto base64 encodes the $value - you must base64 encode it yourself if putting it in via yaml
    kubectl create secret generic "$secret" --from-literal="$secret=$value"
}

# there is no --format or -o namespace as of Kubernetes 1.15 so have to just print 5th col
current_namespace="$(kubectl config get-contexts "$(kubectl config current-context)" --no-headers | awk '{print $5}')"

if [ $# -gt 0 ]; then
    for arg; do
        load_secret "$arg"
    done
else
    while read -r secret; do
        secret="${secret#k8s}"
        secret="${secret#kubernetes}"
        secret="${secret#-}"
        secret="${secret#_}"
        load_secret "$secret"
    done < <(gcloud secrets list --filter="labels.kubernetes-namespace=$current_namespace" --format='value(name)')
fi
