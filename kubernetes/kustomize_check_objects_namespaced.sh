#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-13 08:08:02 +0100 (Sat, 13 Aug 2022)
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
Kustomize builds and checks the resulting Kubernetes yaml for objects without namespaces specified, which can easily result in deployments to the wrong namespace

Useful to find common mistakes in YAMLs or Helm chart templates pulled through Kustomize that don't have namespaces unless you specify it explicitly in the kustomization.yaml

Uses the adjacent script kubernetes_check_objects_namespaces.sh

Requires yq version 4.18.1+
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

dir="${1:-.}"

cd "$dir"

yaml="$(kustomize build --enable-helm)"

"$srcdir/kubernetes_check_objects_namespaced.sh" <<< "$yaml"
