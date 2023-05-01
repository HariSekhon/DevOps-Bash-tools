#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-12 15:34:19 +0000 (Thu, 12 Nov 2020)
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
Reads kubernetes yaml from stdin, extracts all namespace names and creates the namespaces via kubectl in the current context

This is needed because on blank installs doing a 'kubectl diff' can result in the following error:

    Error from server (NotFound): namespaces \"blah\" not found

Instead you can first precreate the namespaces if they don't already exist, after which the diff will succeed:

    ${0##*/} file.yaml file2.yaml ...

or

    kustomize build | ${0##*/}


Since this script applies to the current kubectl context, it is best used as part of other scripts such as kustomize_diff_apply.sh where the kube config and context are isolated and set to avoid race conditions by depending on global kube config which could be concurrently naively changed during execution by other scripts/shells
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file.yaml> <file2.yaml> ...]"

help_usage "$@"

no_more_opts "$@"

namespaces="$(awk '/^[[:space:]]*namespace:[[:space:]]*[a-z0-9]([-a-z0-9]*[a-z0-9])?[[:space:]]*$/{print $2}' "$@" | sort -u)"

current_namespaces="$(kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}')"

for namespace in $namespaces; do
    if grep -Fxq "$namespace" <<< "$current_namespaces"; then
        echo "namespace '$namespace' aleady exists"
    else
        kubectl create namespace "$namespace"
    fi
    echo
done
