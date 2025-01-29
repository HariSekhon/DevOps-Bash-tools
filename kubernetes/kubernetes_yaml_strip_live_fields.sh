#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-18 23:49:51 +0700 (Wed, 18 Dec 2024)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Strips live fields from Kubernetes yaml objects

Useful so you can do 'kubectl diff' or 'kubectl apply' without hitting annoying errors about immutable fields
left in exports from 'kubectl get ... -o yaml'

Reads from files or standard input and outputs to standard output like a standard unix filter program for shell piping


Immutable fields removed:

    - metadata.creationTimestamp,
    - metadata.uid,
    - metadata.resourceVersion,
    - metadata.selfLink,
    - metadata.generation,
    - status,
    - spec.clusterIP,
    - spec.loadBalancerIP,
    - spec.template.metadata.creationTimestamp
"
#- metadata.annotations (optional toggle with --strip-annotations)

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files>]"

help_usage "$@"

#min_args 1 "$@"

strip_yaml(){
	yq eval \
		'del(
		  .metadata.creationTimestamp,
		  .metadata.uid,
		  .metadata.resourceVersion,
		  .metadata.selfLink,
		  .metadata.generation,
		  .status,
		  .spec.clusterIP,
		  .spec.loadBalancerIP,
		  .spec.template.metadata.creationTimestamp
		)' -
}

if [ $# -eq 0 ]; then
    log "Reading from standard input"
	cat "$@" | strip_yaml
else
	for file; do
        strip_yaml < "$file"
    done
fi
