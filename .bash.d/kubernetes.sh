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
#                  K u b e r n e t e s   /   O p e n S h i f t
# ============================================================================ #

# minishift oc-env > ~/.minishift.env
# shellcheck disable=SC1090
[ -f ~/.minishift.env ] && . ~/.minishift.env

kubectl_opts="${KUBECTL_OPTS:-}"
# set K8S_NAMESPACE in local .bashrc or similar files for environments where your ~/.kube/config
# gets regenerated daily with certification authentication from a kerberos login script, which
# resets the 'kcd bigdata' namespace change. This way you automatically send the right namespace every time
if [ "${K8S_NAMESPACE:-}" ]; then
    kubectl_opts="-n $K8S_NAMESPACE"
fi
# TODO: might split this later
oc_opts="$kubectl_opts"

#k(){
#    # want opts auto split, do not quote $kubectl_opts
#    # shellcheck disable=SC2086
#    kubectl $kubectl_opts "$@"
#}
#
#oc(){
#    # want opts auto split, do not quote $kubectl_opts
#    # shellcheck disable=SC2086
#    command oc $oc_opts "$@"
#}

k(){
    # shellcheck disable=SC2086
    case "$(k8s_or_openshift)" in
            openshift)   command oc $oc_opts "$@"
                         ;;
                  k8s)   command kubectl $kubectl_opts "$@"
                         ;;
                    *)   command kubectl $kubectl_opts "$@"
                         ;;
    esac
}

# 'k8s-app' label is set by dashboard creation but who uses that
k8s_get_pod_opts="-o wide -L app,env"

# this is one of the most used things out there, even more than ping
alias p="k get po \$k8s_get_pod_opts"
alias wp=watchpods
alias ke=kubeexec

alias use="k config use-context"
alias contexts="k config get-contexts"
#alias context="k config current-context"
context(){ k config current-context; }
# contexts has this info and is more useful
#alias clusters="k config get-clusters"

alias kcd='kubectl config set-context $(kubectl config current-context) --namespace'

alias menv='eval $(minikube docker-env)'

# looks like both of these work on OpenShift context
#
# 'kubectl get pods'
#
# 'oc get pods'

# figure out if we're using k8s or openshift via most recent commands - return either 'k8s' or 'openshift'
k8s_or_openshift(){
    local last_k8s_cmd
    last_k8s_cmd="$(
        history |
        grep -v history |
        grep -Eo -e '\<oc\>' \
                 -e '\<kubect[l]\>' \
                 -e '\<minikub[e]\>' \
                 -e '\<minishif[t]\>' |
        tail -n 1
    )"
    case "$last_k8s_cmd" in
            oc|minishift)   echo openshift
                            ;;
        kubectl|minikube)   echo k8s
                            ;;
                       *)   echo unknown
                            ;;
    esac
}

oc_get_pods(){
    # shellcheck disable=SC2086
    oc get pods $k8s_get_pod_opts
}

k8s_get_pods(){
    # shellcheck disable=SC2086
    k get pods $k8s_get_pod_opts
}

get_pods(){
    #case "$(k8s_or_openshift)" in
    #        openshift)   oc_get_pods
    #                     ;;
    #              k8s)   k8s_get_pods
    #                     ;;
    #                *)   k8s_get_pods
    #                     ;;
    #esac
    #
    # k8s functions now include k8s vs oc detection, no need for above or would end up double calling k8s_or_openshift
    k8s_get_pods
}
export -f get_pods

get_pod(){
    local filter="${1:-.*}"
    get_pods |
    grep -v '^NAME[[:space:]]' |
    awk "/$filter/{print \$1; exit}"
}

watchpods(){
    # watch on Mac (brew installed) doesn't have -x switch and doesn't work on even 'export -f function'
    # leave using kubectl call for now as that works on openshift too
    watch "
        echo 'Context: '
        echo
        kubectl config current-context
        echo
        echo
        echo 'Pods:'
        echo
        kubectl $kubectl_opts get pods $k8s_get_pod_opts 2>&1
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

kubeexec(){
    local pod
    pod="$(k8s_get_pod "$1")"
    shift
    kubectl exec -ti "$pod" "$@" /bin/sh
}

k8s_get_token(){
    kubectl describe secret -n kube-system \
        "$(kubectl get secrets -n kube-system | grep default | cut -f1 -d ' ')" |
    grep '^token' |
    awk '{print $2}'
}

k8s_get_api(){
    local context
    local cluster
    context="$(context)"
    cluster="$(k config view -o jsonpath="{.contexts[?(@.name == \"$context\")].context.cluster}")"
    k config view -o jsonpath="{.clusters[?(@.name == \"$cluster\")].cluster.server}"
    echo
}
