#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-29 19:15:08 +0100 (Fri, 29 Jul 2022)
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
Creates a Kubernetes sealed secret from a given secret in the current or given namespace

- generates sealed secret yaml
- annotates existing secret to be able to be managed by sealed secrets
- creates sealed secret in the same namespace

Useful to migrate existing secrets to sealed secrets which are safe to commit to Git

See kubernetes_secrets_to_sealed_secrets.sh to quickly migrate all your secrets to sealed secrets

Use kubectl_secrets_download.sh to take a backup of existing kubernetes secrets first


Requires kubectl and kubeseal to both be in the \$PATH and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<secret_name> [<namespace> <context>]"

help_usage "$@"

min_args 1 "$@"

secret="$1"
namespace="${2:-}"
context="${3:-}"

if [[ "$secret" =~ kubernetes\.io/service-account-token ]]; then
    echo "WARNING: skipping touching secret '$secret' for safety"
    exit 0
fi

kube_config_isolate

if [ -n "$context" ]; then
    kube_context "$context"
fi
if [ -n "$namespace" ]; then
    kube_namespace "$namespace"
fi

yaml="sealed-secret-$secret.yaml"

timestamp "Generating sealed secret for secret '$secret'"

kubectl get secret "$secret" -o yaml |
kubeseal -o yaml > "$yaml"

timestamp "Generated:  $yaml"

timestamp "Annotating secret '$secret' to be managed by sealed-secrets controller"

kubectl annotate secrets "$secret" 'sealedsecrets.bitnami.com/managed=true' --overwrite

timestamp "Applying sealed secret '$secret'"

kubectl apply -f "$yaml"
