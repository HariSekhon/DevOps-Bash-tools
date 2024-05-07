#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-05-01 23:50:24 +0400 (Wed, 01 May 2024)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads Rancher kubectl configs for all kubernetes clusters in Rancher
to a directory structure matching the cluster names under the current or given directory

This is fastest way to get set up with local kubectl access in new Rancher environments

Generates a .envrc in each directory to quickly auto-load using direnv if no .envrc already exists

Also generates a local kubeconfig.all in the top level directory with its own .envrc if you want to use that instead

Requires Rancher CLI to be set up and configured, as well as jq


See also:

    install_rancher_cli.sh
    aws_kube_creds.sh  - same as this script but for AWS EKS clusters
    gke_kube_creds.sh  - same as this script but for GCP GKE clusters
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<directory> <cluster1> <cluster2> <cluster3>...]"

help_usage "$@"

if ! type -P rancher &>/dev/null; then
    "$srcdir/../install/install_rancher_cli.sh"
fi

dir="${1:-.}"
shift || :

cd "$dir" || die "Failed to cd to '$dir'"

if [ $# -gt 0 ]; then
    clusters="$*"
else
    timestamp "Getting list of Rancher clusters"
    clusters="$(rancher clusters ls --format json | jq -r '.Cluster.name')"
    echo
fi

for cluster in $clusters; do
    timestamp "Getting kubeconfig for Rancher cluster '$cluster'"
    mkdir -p "$cluster"
    base="$PWD/$cluster"
    kubeconfig="$base/kubeconfig"
    envrc="$base/.envrc"
    rancher clusters kubeconfig "$cluster" > "$kubeconfig"
    timestamp "Downloaded '$kubeconfig'"
    if ! [ -f "$envrc" ]; then
        timestamp "Generating '$envrc'"
        cat >> "$envrc" <<-EOF
            export KUBECONFIG="\$PWD/kubeconfig"
EOF
        if type -P direnv &>/dev/null; then
            timestamp "Direnv allowing '$envrc'"
            direnv allow "$envrc"
        fi
    fi
    echo
done

timestamp "Finished downloading Rancher kubeconfigs"

echo
timestamp "Merging configs into $PWD/kubeconfig.all"
# shellcheck disable=SC2012
# find . -maxdepth 2 -name kubeconfig
KUBECONFIG=$(ls "$PWD"/*/kubeconfig | tr '\n' ':')
export KUBECONFIG
kubectl config view --merge --flatten > kubeconfig.all
echo

if ! [ -f .envrc ]; then
    timestamp "Generating $PWD/.envrc"
    cat >> .envrc <<-EOF
    export KUBECONFIG="\$PWD/kubeconfig.all"
EOF
    direnv allow .envrc
    echo
fi

timestamp "Done"
