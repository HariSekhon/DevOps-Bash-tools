#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-08 12:14:14 +0700 (Wed, 08 Jan 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Iterates EKS clusters to list each AWS EKS cluster name and version in the current account

Output format:

<cluster_name>    <version>

Combine with:

    aws_foreach_region.sh - to audit your cluster versions across regions
    aws_foreach_profile.sh - to audit your cluster versions across accounts


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

aws eks list-clusters --output json |
jq -r '.clusters[]' |
while read -r cluster; do
    aws eks describe-cluster --name "$cluster" --output json |
    jq -r '.cluster | [.name, .version] | @tsv'
done
