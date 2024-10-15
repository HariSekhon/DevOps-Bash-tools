#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-15 04:58:14 +0400 (Tue, 15 Oct 2024)
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
Fetch logs from Kubernetes nodes (eg. for support debug requests by vendors)

Uses the adjacent script:

    $srcdir/../monitoring/ssh_dump_logs.sh

Requires Kubectl to be installed and configured to be on the right Kubernetes cluster context as it uses this to
determine the nodes

User - set your SSH_USER environment variable if your login user is different to your local \$USER

SSH key - if you need to set to an alternative SSH key or
          else add it to a local ssh-agent for passwordless authentication to work

See here for details:

    $srcdir/../monitoring/ssh_dump_logs.sh --help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

timestamp "Getting Kubernetes nodes via kubectl"
nodes="$(kubectl top nodes --no-headers | awk '{print $1}')"
num_nodes="$(wc -l <<< "$nodes" | sed 's/[[:space:]]//g')"
timestamp "Found $num_nodes nodes"
echo

# want splitting
# shellcheck disable=SC2086
"$srcdir/../monitoring/ssh_dump_logs.sh" $nodes
