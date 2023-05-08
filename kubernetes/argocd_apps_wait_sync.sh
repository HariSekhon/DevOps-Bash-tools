#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-05-08 20:31:59 +0100 (Mon, 08 May 2023)
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
Sync all ArgoCD apps matching an optional given ERE regex filter

Requires ArgoCD CLI to be installed and configured for authentication

You may also want to set some environment variables such as:

    export ARGOCD_SERVER='argocd.domain.com'
    export ARGOCD_OPTS='--grpc-web --timeout 600'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<name_filter>]"

help_usage "$@"

max_args 1 "$@"

filter="${1:-.*}"

argocd app list |
awk '{print $1}' |
{ grep -E "$filter" || : ; } |
while read -r app; do
    echo "Syncing app '$app':"
    echo
    cmd=(argocd app wait "$app" --sync --operation --health)
    echo "${cmd[*]}"
    "${cmd[@]}"
    echo
    echo
done
