#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-03-02 18:59:16 +0000 (Tue, 02 Mar 2021)
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
#srcdir="$(dirname "${BASH_SOURCE[0]}")"

# XXX: prevents race conditions from changes in global context
kube_config_isolate(){
    local tmp="/tmp/.kube"
    local default_kubeconfig="${HOME:-$(cd ~ && pwd)}/.kube/config"
    local original_kubeconfig="${KUBECONFIG:-$default_kubeconfig}"

    mkdir -pv "$tmp"

    kubeconfig="$tmp/config.${EUID:-$UID}.$$"

    if [ -f "$original_kubeconfig" ]; then
        cp -f "$original_kubeconfig" "$kubeconfig"
    fi

    export KUBECONFIG="$kubeconfig"
}
