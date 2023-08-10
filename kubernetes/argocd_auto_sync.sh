#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-08-10 21:06:30 +0100 (Thu, 10 Aug 2023)
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
Enables/Disable ArgoCD Auto-Sync

Need to be able to manually fix apps sometimes, without ArgoCD reverting the changes before they're testing and committed

If ArgoCD apps of the name 'argocd' and 'apps' are found, then toggles them too to prevent cascading auto-sync re-enabling via the App-of-Apps pattern
(see https://github.com/HariSekhon/Kubernetes-configs)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="on/off [<app>]"

help_usage "$@"

min_args 1 "$@"

check_bin argocd
check_env_defined "ARGOCD_SERVER"

if [ "$1" = on ]; then
    automated_or_none="automated"
    msg="enabling auto-sync on app"
elif [ "$1" = off ]; then
    automated_or_none="none"
    msg="disabling auto-sync on app"
else
    usage "invalid first arg given, must be either 'on' or 'off'"
fi

# custom env var, found in .envrc in Kubernetes and DevOps-Bash-tools .envrc files
if [ -n "${ARGOCD_APP:-}" ]; then
    app="$ARGOCD_APP"
elif [ $# -eq 2 ]; then
    app="$2"
else
    usage "\$ARGOCD_APP not defined and no second arg passed for app to enable/disable auto-sync for"
fi

apps="$(argocd app list -o name | sed 's|argocd/||')"

# App-of-Apps which would re-enable the app must be disabled first
for base_app in argocd apps; do
    if grep -Fxq 'argocd' <<< "$apps"; then
        timestamp "$msg '$base_app'"
        argocd app set "$base_app" --sync-policy "$automated_or_none"
    fi
    echo >&2
done

timestamp "$msg '$app'"
argocd app set "$app" --sync-policy "$automated_or_none"
