#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-07-28 14:56:41 +0100 (Sun, 28 Jul 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                              K u b e r n e t e s
# ============================================================================ #

k(){
    kubectl_opts=""
    if [ "${K8S_NAMESPACE:-}" ]; then
        kubectl_opts="-n $K8S_NAMESPACE"
    fi
    # shellcheck disable=SC2086
    kubectl $opts "$@"
}

get_pod(){
    local filter="${1:-.*}"
    k get pods | grep "$filter" | head -n1
}

watchpods(){
    watch "
        echo
        kubectl config current-context
        echo
        kubectl $kubectl_opts get pods
        echo
    "
}

kdesc(){
    k describe "$@"
}

kdp(){
    kdesc pods "$@"
}

kdelp(){
    k delete pod "$@"
}

# this is one of the most used things out there, even more than ping
alias p="k get po"
alias wp=watchpods

alias contexts="k config get-contexts"
alias context="k config current-context"

alias kcd="kubectl config set-context $(kubectl config current-context) --namespace"

alias menv='eval $(minikube docker-env)'
