#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-06-18 11:43:50 +0100 (Fri, 18 Jun 2021)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Filter program to generate ArgoCD namespace resource whitelist from a given Kubernetes YAML or Kustomize build output

YAML can be supplied as a file argument or via standard input. If no file is given, waits for stdin like a standard unix filter program

Outputs YAML for the namespaceResourceWhitelist section of argocd-project.yaml

A full argocd-project.yaml is already provided at the URL below with all the most common object permissions already populated via the output from this script against my production environment

    https://github.com/HariSekhon/Kubernetes-configs

Uses adjacent script kubernetes_resource_types.sh

Tested on ArgoCD 2.0.3
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file.yaml> <file2.yaml> ...]"

help_usage "$@"

#min_args 1 "$@"

echo "  namespaceResourceWhitelist:"
"$srcdir/kubernetes_resource_types.sh" "$@" |
while read -r group kind; do
    # Cluster resources, ignore these
    if [[ "$kind" =~ Namespace|PriorityClass|StorageClass ]]; then
        continue
    fi
    group="${group%/*}"
    if [ "$group" = v1 ]; then
        group=""
    fi
    if [ "$group" = "" ]; then
        group="''"
    fi
    echo "  - group: $group"
    echo "    kind: $kind"
done
