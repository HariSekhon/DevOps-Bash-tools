#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-07 15:45:38 +0000 (Fri, 07 Jan 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Gets the ArgoCD initial admin password from the environment or Kubernetes secret

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "${ARGOCD_PASSWORD:-}" ]; then
    echo "using \$ARGOCD_PASSWORD from environment" >&2
elif kubectl get secret -n argocd argocd-initial-admin-secret &>/dev/null; then
    ARGOCD_PASSWORD="$(kubectl -n argocd get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)"
fi

if [ -z "${ARGOCD_PASSWORD:-}" ]; then
    echo "ERROR: failed to determine ARGOCD_PASSWORD from environment or kubernetes" >&2
    exit 1
fi

# if sourced, export ARGOCD_PASSWORD, if subshell, echo it
#if [[ "$_" != "$0" ]]; then
    export ARGOCD_PASSWORD
#else
    echo -n "$ARGOCD_PASSWORD"  # no newline so we can pipe straight to pbcopy / xclip or similar
#fi
