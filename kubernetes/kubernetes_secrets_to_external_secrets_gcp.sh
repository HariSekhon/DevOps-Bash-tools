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
Creates Kubernetes external secrets yamls from all existing Kubernetes secrets in the current or given namespace

For every secret, performs the following actions via kubernetes_secrets_to_external_secret_gcp.sh:

- generates external secret yaml
- checks the GCP Secret Manager secret exists
  - if it doesn't, creates it
  - if it does, validates that its content matches the existing secret in Kubernetes
- creates external secret in the same namespace
- omits:
  - type kubernetes.io/service-account-token
  - type tls with Cert Manager annotation

Useful to migrate existing secrets to external secrets referencing GCP Secret Manager

Use kubectl_secrets_download.sh to take a backup of existing kubernetes secrets first


Requires kubectl and GCloud SDK to both be in the \$PATH and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace> <context>]"

help_usage "$@"

max_args 2 "$@"

check_bin kubectl

namespace="${1:-}"
context="${2:-}"

kube_config_isolate

if [ -n "$context" ]; then
    kube_context "$context"
fi
if [ -n "$namespace" ]; then
    kube_namespace "$namespace"
fi

if [ "${namespace:-}" ]; then
    namespace="$(kube_current_namespace)"
fi

for secret in $(kubectl get secrets -o name | sed 's|^secret/||'); do
    secret_json="$(kubectl get secret "$secret" -o json)"
    secret_type="$(jq -r '.type' <<< "$secret_json")"
    if [ "$secret_type" = "kubernetes.io/service-account-token" ]; then
        timestamp "Skipping touching service account token secret '$secret' for safety"
        echo
        continue
    fi
    if [ "$secret_type" = "kubernetes.io/tls" ]; then
        tls_cert_manager_issuer="$(jq -r '.metadata.annotations."cert-manager.io/issuer-name"' <<< "$secret_json")"
        if [ -n "$tls_cert_manager_issuer" ]; then
            timestamp "Skipping touching tls secret '$secret' because its managed by Cert Manager"
            echo
            continue
        fi
    fi
    "$srcdir/kubernetes_secret_to_external_secret_gcp.sh" "$secret"
    echo
done
