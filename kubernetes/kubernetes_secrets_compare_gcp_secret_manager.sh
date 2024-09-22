#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-07-26 00:38:43 +0100 (Wed, 26 Jul 2023)
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
Compares each Kubernetes secret to GCP Secret Manager

Checks for each key in the kubernetes secret:

- that the kubernetes secret key exists in GCP Secret Manager
- that the kubernetes secret key value matches the value of the latest version in GCP Secret Manager

Useful to verify before enabling pulling external secrets from GCP Secret Manager

See kubernetes_secrets_to_external_secrets_gcp.sh to quickly migrate all your secrets to external secrets

Use kubectl_secrets_download.sh to take a backup of existing kubernetes secrets first


Requires kubectl and GCloud SDK to both be in the \$PATH and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace> <context>]"

help_usage "$@"

max_args 2 "$@"

check_bin kubectl
check_bin gcloud

namespace="${1:-}"
context="${2:-}"

kube_config_isolate

if [ -n "$context" ]; then
    kube_context "$context"
fi
if [ -n "$namespace" ]; then
    kube_namespace "$namespace"
fi

if [ -z "${namespace:-}" ]; then
    namespace="$(kube_current_namespace)"
fi

secrets="$(
    kubectl get secrets |
    grep -v '^NAME[[:space:]]' |
    awk '{print $1}'
)"

#max_len=0
#while read -r secret; do
#    if [ "${#secret}" -gt "$max_len" ]; then
#        max_len="${#secret}"
#    fi
#done <<< "$secrets"

# shellcheck disable=SC2317
check_secret(){
    local secret="$1"
    local secret_json
    local secret_type
    secret_json="$(kubectl get secret "$secret" -o json)"
    secret_type="$(jq -r '.type' <<< "$secret_json")"
    if [ "$secret_type" = "kubernetes.io/service-account-token" ]; then
        print_result "$secret" "n/a" "n/a" "skip_k8s_service_account"
        return
    fi
    if [ "$secret_type" = "kubernetes.io/tls" ]; then
        tls_cert_manager_issuer="$(jq -r '.metadata.annotations."cert-manager.io/issuer-name"' <<< "$secret_json")"
        if [ -n "$tls_cert_manager_issuer" ]; then
            print_result "$secret" "n/a" "n/a" "skip_tls_cert_manager"
            return
        fi
    fi

    local keys
    keys="$(jq -r '.data | keys[]' <<< "$secret_json")"
    if [ -z "$keys" ]; then
        print_result "$secret" "n/a" "n/a" "FAILED_TO_GET_SECRET_KEYS"
        return 1
    fi
    local num_keys
    num_keys="$(wc -l <<< "$keys" | sed 's/[[:space:]]//g')"
    for key in $keys; do
        if [ "$num_keys" -eq 1 ] || [ "$key" = "$secret" ]; then
            gcp_secret="$secret"
        else
            gcp_secret="$secret-$(tr -C '[:alnum:]-\n' '-' <<< "$key")"
        fi
        check_key "$secret" "$key" "$gcp_secret" "$secret_json"
    done
}

# shellcheck disable=SC2317
check_key(){
    local secret="$1"
    local key="$2"
    local gcp_secret="$3"
    local secret_json="$4"
    local k8s_secret_value
    local gcp_secret_value
    local result
    # if the secret has a dash in it, then you need to quote it whether .data."$secret" or .data["$secret"]
    k8s_secret_value="$(jq -r ".data[\"$key\"]" <<< "$secret_json" | base64 --decode)"
    if [ -z "$k8s_secret_value" ]; then
        print_result "$secret" "$key" "$gcp_secret" "FAILED_TO_GET_K8S_KEY_VALUE"
        return 1
    fi

    if ! gcloud secrets list --format='value(name)' | grep -Fxq "$gcp_secret"; then
        print_result "$secret" "$key" "$gcp_secret" "MISSING_ON_GCP"
        return 1
    else
        gcp_secret_value="$("$srcdir/../gcp/gcp_secret_get.sh" "$gcp_secret")"
        # if it's GCP service account key
        # false positive - trivy:ignore:gcp-service-account doesn't work
        # trivy:ignore:gcp-service-account
        if grep -Fq '"type": "service_account"' <<< "$gcp_secret_value"; then
            if [ -n "$(diff -w <(echo "$gcp_secret_value") <(echo "$k8s_secret_value") )" ]; then
                print_result "$secret" "$key" "$gcp_secret" "MISMATCHED_GCP_SERVICE_ACCOUNT_VALUE"
                return 1
            else
                print_result "$secret" "$key" "$gcp_secret" "ok_gcp_service_account_value"
            fi
        elif [ "$gcp_secret_value" = "$k8s_secret_value" ]; then
            print_result "$secret" "$key" "$gcp_secret" "ok_gcp_value_matches"
        else
            print_result "$secret" "$key" "$gcp_secret" "MISMATCHED_GCP_VALUE"
            return 1
        fi
    fi
}

# have all calls standardize the different results to allow column -t alignment ans sorting at the end
# shellcheck disable=SC2317
print_result(){
    local secret="$1"
    local key="$2"
    local gcp_secret="$3"
    local result="$4"
    echo "Kubernetes secret '$secret' key '$key' == GCP secret '$gcp_secret' => $result"
}

export srcdir
export -f check_secret
export -f check_key
export -f print_result
while read -r secret; do
    echo "check_secret '$secret'"
done <<< "$secrets" |
parallel |
column -t |
sort -k11r
