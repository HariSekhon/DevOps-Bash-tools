#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-02-02 15:23:26 +0000 (Thu, 02 Feb 2023)
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
Finds live deprecated objects in the current Kubernetes cluster

Dumps all Kubernetes objects from the current kubectl cluster context to a directory in /tmp and then runs Pluto against it to detect deprecated API objects affecting your Kubernetes cluster upgrades

Newer versions of Pluto can 'pluto detect-all-in-cluster', but on real-world clusters I've found that this finds different deprecated API objects compared to detect-files on dumped objects, so this script has been updated to do both for comparison

See here for more details:

    https://github.com/FairwindsOps/pluto/issues/461

Requires 'kubectl' and a recent 'pluto' binary to be in the \$PATH (newer Pluto is required for the second pass of detect-all-in-cluster), as well as the kubectl context configured and set as current context
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

export KUBECTL_GET_ALL_SEPARATOR='---'

dir="/tmp/${0##*/}.$$"
dumpfile="$dir/all.yaml"

mkdir -pv "$dir"

timestamp "Dumping all live Kubernetes objects to $dumpfile (this will take a few minutes)"
"$srcdir/kubectl_get_all.sh" --all-namespaces -o yaml > "$dumpfile"
echo >&2

timestamp "Scanning dumped objects with Pluto"
echo >&2
# returns exit code 3 when deprecated objects are found so doesn't run the next detect-all-in-cluster without ignoring the exit code
pluto detect-files -d "$dir" || :
echo >&2

timestamp "Scanning live cluster as real-world testing shows this finds different results"
echo >&2
pluto detect-all-in-cluster
