#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-03-02 18:59:16 +0000 (Tue, 02 Mar 2021)
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
#srcdir="$(dirname "${BASH_SOURCE[0]}")"

# XXX: prevents race conditions from changes in global context
kube_config_isolate(){
    local tmp="/tmp/.kube"
    local default_kubeconfig="${HOME:-$(cd ~ && pwd)}/.kube/config"
    local original_kubeconfig="${KUBECONFIG:-$default_kubeconfig}"

    mkdir -pv "$tmp"

    kubeconfig="$tmp/config.${EUID:-$UID}.$$"

    if [ -f "$original_kubeconfig" ]; then
        cp -f -- "$original_kubeconfig" "$kubeconfig"
    elif [ -f "$default_kubeconfig" ]; then
        cp -f -- "$default_kubeconfig" "$kubeconfig"
    elif [ -f "$PWD/.kube/config" ]; then
        cp -f -- "$PWD/.kube/config" "$kubeconfig"
    fi

    export KUBECONFIG="$kubeconfig"
}

# run 'kubectl config use-context' only if not already on the desired context, in order to minimize noise
kube_context(){
    local context="$1"
    local namespace="${2:-}"
    local current_context
    current_context="$(kube_current_context)"
    if [ "$context" != "$current_context" ]; then
        kubectl config use-context "$context" >&2
    fi
    kube_namespace "$namespace"
}

kube_current_context(){
    kubectl config current-context
}

kube_current_namespace(){
    kubectl config get-contexts |
    awk "/$(kube_current_context)/ {print \$NF}"
}

kube_namespace(){
    local namespace="$1"
    local current_namespace
    current_namespace="$(kube_current_namespace)"
    if [ "$namespace" != "$current_namespace" ]; then
        local current_context
        current_context="$(kube_current_context)"
        kubectl config set-context "$current_context" --namespace "$namespace" >&2
    fi
}

run_static_pod(){
    local name="$1"
    local image="$2"
    shift || :
    shift || :
    local pod_json
    pod_json="$(kubectl get pod "$name" "$@" -o json 2>/dev/null || :)"

    run(){
        kubectl run -ti --rm --restart=Never "$name" --image="$image" "$@" -- /bin/sh
    }

    if [ -n "$pod_json" ]; then
        if jq -e '.status.phase == "Running"' <<< "$pod_json" >/dev/null; then
            exec kubectl exec -ti "$name" "$@" -- /bin/sh
        elif jq -e '.status.phase == "Succeeded" or .status.phase == "Failed"' <<< "$pod_json" >/dev/null; then
            kubectl delete pod "$name" "$@"
            run "$@"
        else
            echo "ERROR: Pod already exists. Check its state and remove it?"
            kubectl get pod "$name" "$@"
            return 1
        fi
    else
        run "$@"
    fi
}
