#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-07 16:03:39 +0000 (Fri, 07 Jan 2022)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                                  A r g o C D
# ============================================================================ #

# gets default admin pw and copies it to clipboard for quick pasting to UI
alias argopass="argocd_password.sh | copy_to_clipboard"

# XXX: set the following in your local environment:
#
# ARGOCD_SERVER=localhost:8080  # without the http:// or https:// prefix
# ARGOCD_AUTH_TOKEN='<token>'

export ARGOCD_OPTS="--grpc-web"
#export ARGOCD_OPTS="--grpc-web --insecure"  # only in local dev

argosync(){
    local seconds="${1:-60}"
    shift || :
    if [ -z "${ARGOCD_APP:-}" ]; then
        namespace="${K8S_NAMESPACE:-$(kubectl_namespace)}"
        if argocd app list -o name | grep -Fxq "$namespace"; then
            ARGOCD_APP="$namespace"
        fi
    fi
    if [ -n "${ARGOCD_APP:-}" ]; then
        argocd app sync "$ARGOCD_APP" --force "$@"
        argocd app wait "$ARGOCD_APP" --timeout "$seconds" "$@"
    else
        echo "\$ARGOCD_APP is not set" >&2
        return 1
    fi
}
