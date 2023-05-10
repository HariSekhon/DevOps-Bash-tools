#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-05-10 18:23:34 +0100 (Wed, 10 May 2023)
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
Generates YAML list of ArgoCD resources to whitelist for both Cluster and Namespace for an ArgoCD argoproj.io/v1alpha1 AppProject

This is needed if using whitelists in ArgoCD 2.2+ because they restrict showing the child objects unless they are whitelists if using whitelists

Dumps all API object resources from the current Kubernetes cluster context into YAML format to put straight into argocd-project.yaml

If an argocd-project.yaml is given, parses it for existing resource whitelist, merges the two lists in sorted order by Kind and then updates the yaml with an in-place edit
You should have revision controlled your yaml file in Git before you do this - both as a backup of the last good version as well as to see the difference of the edited file

Requires kubectl to be installed and configured, and also yq if a yaml file is given
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<argocd-project.yaml>]"

help_usage "$@"

max_args 1 "$@"

yaml_file="${1:-}"

api_resources="$(
    # there is no -o json as of Kubernetes 1.27
    kubectl api-resources |
    # strip header line
    tail -n +2 || :  # ignore this error:
    # error: unable to retrieve the complete list of server APIs: external.metrics.k8s.io/v1beta1: received empty response for: external.metrics.k8s.io/v1beta1
)"

if [ -n "$yaml_file" ]; then
    [ -f "$yaml_file" ] || die "Given YAML file does not exist: $yaml_file"
fi

echo "clusterResourceWhitelist:"
awk '$(NF-1) ~/false/ {print $NF" "$(NF-2)}' <<< "$api_resources" |
if [ -n "$yaml_file" ]; then
    # pass through api_resources and strip trailing /v1 as it's redundant vs file contents
    sed 's|/v1$| |'
    # add resources from yaml
    yq '.spec.clusterResourceWhitelist[] |
        [ .kind, .group | sub("^$", "v1")] |
        @tsv' "$yaml_file"
else
    # pass through api_resources and strip trailing /v1 as it's redundant vs file contents
    sed 's|/v1$| |'
fi |
column -t |
sort -u |
while read -r kind group; do
    # ArgoCD doesn't show pods for v1 Pod, only '' Pod in the project resource whitelist
    if [ "$group" = "v1" ]; then
        group="''"
    fi
    echo "  - group: $group"
    echo "    kind: $kind"
done |
if [ -n "$yaml_file" ]; then
    yq -i ".spec.clusterResourceWhitelist = $(yq '.' -o json)" "$yaml_file"
else
    cat
fi
echo
echo "namespaceResourceWhitelist:"
awk '$(NF-1) ~/true/ {print $NF" "$(NF-2)}' <<< "$api_resources" |
if [ -n "$yaml_file" ]; then
    # pass through api_resources and strip trailing /v1 as it's redundant vs file contents
    sed 's|/v1$| |'
    # add resources from yaml
    yq '.spec.namespaceResourceWhitelist[] |
        [ .kind, .group | sub("^$", "v1")] |
        @tsv' "$yaml_file"
else
    # pass through api_resources and strip trailing /v1 as it's redundant vs file contents
    sed 's|/v1$| |'
fi |
column -t |
sort -u |
while read -r kind group; do
    if [ "$group" = "v1" ]; then
        group="''"
    fi
    echo "  - group: $group"
    echo "    kind: $kind"
done |
if [ -n "$yaml_file" ]; then
    yq -i ".spec.namespaceResourceWhitelist = $(yq '.' -o json)" "$yaml_file"
else
    cat
fi
