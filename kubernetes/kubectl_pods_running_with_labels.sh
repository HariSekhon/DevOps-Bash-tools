#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-20 17:52:17 +0200 (Tue, 20 Aug 2024)
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
Lists Kubernetes running pods with labels matching key=value pair arguments, returning one pod name per line (convenient for shell piping)

All arguments after the first dash prefixed argument are treated as options to kubectl. This is where you should specify -n <namespace> or --all-namespaces


Requires kubectl to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="key=value key2=value2 ... [<kubectl_options>]"

help_usage "$@"

min_args 1 "$@"

kube_config_isolate

label_args=()

validate_label(){
    local arg="$1"
    if ! [[ "$arg" =~ ^[[:alnum:]-]+=[[:alnum:]-]+$ ]]; then
        die "Invalid label key=value pair given (does not match regex validation): $arg"
    fi
}

until [ $# -lt 1 ]; do
    case $1 in
        -*) break
            ;;
         *) validate_label "$1"
            label_argss+=(-l "$1")
            ;;
    esac
    shift || :
done

kubectl get pods "${label_args[@]}" \
                 --field-selector=status.phase=Running \
                 -o json "$@" | \
  jq -r '
    .items[] |
    select(.status.containerStatuses[0].state.running != null) |
    select(.spec.containers[].image |
      contains("artifacthub.informaticacloud.com")) |
    .metadata.name
  '
