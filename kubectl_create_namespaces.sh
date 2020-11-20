#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-12 15:34:19 +0000 (Thu, 12 Nov 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Reads kubernetes yaml from stdin, extracts all namespace names and creates the namespaces with kubectl

This is needed because on blank installs doing something like

    kustomize build | kubectl diff -f -

fails with an error like:

    Error from server (NotFound): namespaces \"blah\" not found

Instead you can first pipe it through this script to precreate the namespaces so the kubectl diff succeeds
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file.yaml> <file2.yaml>]"

help_usage "$@"

no_more_opts "$@"


while read -r namespace; do
    if kubectl get ns "$namespace" &>/dev/null; then
        echo "namespace '$namespace' aleady exists"
    else
        kubectl create namespace "$namespace"
    fi
    echo
done < <(awk '/namespace:/{print $2}' "$@" | sort -u)
