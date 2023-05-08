#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-09-01 10:54:32 +0100 (Thu, 01 Sep 2022)
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
Installs the Helm Charts from one or more Kustomize kustomization.yaml files using Helm CLI so that tools like Nova can be run on the live helm releases to detect outdated charts

All arguments are passed straight to yq and must be kustomization.yaml files or valid --options

Environment variables:
  - if \$SKIP_EXISTING_HELM_INSTALLATIONS is set to any value, then will skip those installations (useful for CI/CD retries without failing on existing installation from previous run)
  - if \$SKIP_ERRORS is set to any value, will ignore failures to install each helm chart, such as webhooks failing to contact cert-manager (useful for CI/CD runs where you just want the charts installed to test outdated release versions with Nova such as https://github.com/HariSekhon/Kubernetes-configs/actions/workflows/kustomize-nova.yaml)

Uses adjacent script kustomize_parse_helm_charts.sh and is used in CI/CD GitHub Actions for repo:

    https://github.com/HariSekhon/Kubernetes-configs CI/CD GitHub Actions


Requires Helm and yq to be installed and installs them if not found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="kustomization.yaml kustommization2.yaml..."

help_usage "$@"

min_args 1 "$@"

type -P helm &>/dev/null || "$srcdir/../setup/install_helm.sh"
type -P yq &>/dev/null || "$srcdir/../setup/install_yq.sh"

# if there are no repositories to show will return exit code 1 so || :
helm_repos="$(helm repo list -o yaml | yq -r '.[] | [.name, .url] | @tsv' || :)"

if [ -n "${SKIP_EXISTING_HELM_INSTALLATIONS:-}" ]; then
    helm_installations="$(helm ls -A -o json | jq -r '.[].name')"
fi

"$srcdir/kustomize_parse_helm_charts.sh" "$@" |
while read -r repo_url name version values_file; do
    if [ -n "${SKIP_EXISTING_HELM_INSTALLATIONS:-}" ]; then
        if grep -Fxq "$name" <<< "$helm_installations"; then
            timestamp "Skipping existing Helm installation: $name"
            continue
        fi
    fi
    if [ "$values_file" = null ]; then
        values_file=""
    fi
    if ! grep -Eq "^${name}[[:space:]]+${repo_url}[[:space:]]*$" <<< "$helm_repos"; then
        timestamp "Adding Helm repo '$repo_url' as name '$name'"
        # might fail here if you've already installed a repo with this name, in which case, fix your repos, we don't want to remove/modify your existing repos
        helm repo add "$name" "$repo_url"
    fi
    timestamp "Installing Helm chart '$name' version '$version' from '$repo_url'"
    if [ -n "${SKIP_ERRORS:-}" ]; then
        set +e
    fi
    helm install "$name" "$name/$name" --version "$version" --create-namespace --namespace "$name" ${values_file:+--values "$values_file"}
    if [ -n "${SKIP_ERRORS:-}" ]; then
        set -e
    fi
    echo
done
