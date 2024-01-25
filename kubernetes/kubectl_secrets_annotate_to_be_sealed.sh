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
Annotate all secrets in the current or given namespace to allow Sealed Secret overwrite

Useful to fix update conflicts in ArgoCD where the sealed secret can't be unmapped

This is usually done as part of the migration script kubernetes_secrets_to_sealed_secrets.sh but if reapplying or updating secrets then this may be needed

See Also:

    kubernetes_secret_to_sealed_secret.sh
    kubernetes_secrets_to_sealed_secrets.sh
    kubectl_secrets_download.sh (to take a backup of secrets first)


Requires kubectl to be in the \$PATH and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace> <context>]"

help_usage "$@"

#min_args 1 "$@"

namespace="${1:-}"
context="${2:-}"

kube_config_isolate

if [ -n "$context" ]; then
    kube_context "$context"
fi
if [ -n "$namespace" ]; then
    kube_namespace "$namespace"
fi

kubectl get secrets |
# don't touch the default generated service account tokens for safety
grep -v kubernetes.io/service-account-token |
# remove header
grep -v '^NAME[[:space:]]' |
awk '{print $1}' |
while read -r secret; do
    timestamp "Annotating secret '$secret' to be managed by sealed-secrets controller"
    kubectl annotate secrets "$secret" 'sealedsecrets.bitnami.com/managed=true' --overwrite
    echo
done
timestamp Done
