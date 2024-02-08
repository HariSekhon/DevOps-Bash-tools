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
Updates one of more one Kustomize kustomization.yaml files with the latest version of the charts

All arguments are passed straight to yq and must be kustomization.yaml files

If no argument is given attempts to use a kustomization.yaml in the current working directory for convenience

Uses adjacent script kustomize_parse_helm_charts.sh


Requires Helm and yq to be installed and installs them if not found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="kustomization.yaml [kustomization2.yaml ...]"

help_usage "$@"

any_opt_usage "$@"

#min_args 1 "$@"

type -P helm &>/dev/null || "$srcdir/../install/install_helm.sh"
type -P yq &>/dev/null || "$srcdir/../install/install_yq.sh"

# if there are no repositories to show will return exit code 1 so || :
helm_repos="$(helm repo list -o yaml | yq -r '.[] | [.name, .url] | @tsv' || :)"

# slow to do for every run, leave this as a rarely needed exercise for the caller
#echo
#helm repo update
#echo

for kustomization in "${@:-kustomization.yaml}"; do
    pushd "$(dirname "$kustomization")" >/dev/null
    kustomization="${kustomization##*/}"
    "$srcdir/kustomize_parse_helm_charts.sh" "$kustomization" |
    while read -r repo_url name version _values_file; do
        if ! grep -Eq "^${name}[[:space:]]+${repo_url}[[:space:]]*$" <<< "$helm_repos"; then
            timestamp "Adding Helm repo '$repo_url' as name '$name'"
            # might fail here if you've already installed a repo with this name
            helm repo add "$name" "$repo_url" || die "adding repo '$name' with url '$repo_url' failed, fix your repos as we don't want to remove/modify your existing repos if there is a repo name clash"
        fi
        timestamp "Finding latest Helm chart '$name' version from '$repo_url'"
        latest_version="$(helm search repo "$name" | awk "/^$name\/${name}[[:space:]]/{print \$2}")"
        #helm install "$name" "$name/$name" --version "$version" --create-namespace --namespace "$name" ${values_file:+--values "$values_file"}
        if [ "$version" != "$latest_version" ]; then
            timestamp "Updating '$kustomization' chart '$name' from version '$version' to version '$latest_version'"
            # more accurate but unfortunately strips out --- and all blank spacing lines
            #yq -i ".helmCharts[select(.name == \"$name\")].version = \"$latest_version\""  "$kustomization"
            # for revision controlled kustomization.yaml this is good enough
            sed -i "s/ version:[[:space:]]*$version/ version: $latest_version/" "$kustomization"
        fi
        echo
    done
    popd >/dev/null
done
