#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-10-21 15:30:28 +0100 (Thu, 21 Oct 2021)
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
Counts the total number of running Docker containers on the current Kubernetes cluster in the current namespace

Specify the --namespace or use --all-namespaces to get the total across all namespaces, including the kube-system namespace

Requires kubectl to be in \$PATH and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<--namespace blah | --all-namespaces>"

help_usage "$@"

kubectl get pods "$@" --field-selector status.phase=Running -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.name}{"\n"}' |
wc -l |
sed 's/[[:space:]]*//'
