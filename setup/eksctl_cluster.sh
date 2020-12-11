#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 12:10:23 +0000 (Fri, 11 Dec 2020)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sets up a test AWS EKS cluster using eksctl with 3 worker nodes in a 1-4 node AutoScaling group
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

"$srcdir/install_eksctl.sh"
echo

timestamp "Creating AWS EKS cluster via eksctl"
eksctl create cluster --name mycluster \
                      --version 1.16 \
                      --region us-east-1 \
                      --nodegroup-name standard-workers \
                      --node-type t3.micro \
                      --nodes 3 \
                      --nodes-min 1 \
                      --nodes-max 4 \
                      --managed \
                      --zones us-east-1d,us-east-1f  # might need to tweak these to work around lack of capacity in zones
