#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-28 15:04:50 +0100 (Fri, 28 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs a quick busybox pod on Kubernetes to debug networking / dns

Shares the same busybox pod for successive invocations of this script for speed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<kubectl_options>]"

help_usage "$@"

name=busybox

if kubectl get po "$name" "$@" &>/dev/null; then
    kubectl exec -ti "$name" "$@" -- /bin/sh
else
    kubectl run -ti --rm --restart=Never "$name" --image=busybox "$@" -- /bin/sh
fi
