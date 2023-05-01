#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-11-24 12:40:18 +0000 (Wed, 24 Nov 2021)
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
Adds kubernetes-cluster and kubernetes-namespace labels to a given GCP Secret Manager secret based on the current kubectl context for later use by the gcp_secrets_to_kubernetes.sh script

First argument is used as secret name - if not given prompts for it
Second or more args are passed to 'gcloud secrets'


GCloud SDK and kubectl must both be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<name> [<gcloud_options>]"

help_usage "$@"

min_args 1 "$@"

name="$1"
shift || :

# assumes the context and cluster name are the same which they usually are for AWS, GCP, docker-desktop and minikube
read -r kubernetes_cluster kubernetes_namespace \
    < <(kubectl config get-contexts | awk '/*/{print $2" "$NF}')

gcloud secrets update "$name" --update-labels="kubernetes-cluster=$kubernetes_cluster,kubernetes-namespace=$kubernetes_namespace" "$@"
