#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-04-16 16:37:29 +0100 (Fri, 16 Apr 2021)
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
Find Kubernetes pods belonging to the same deployments / statefulsets that are colocated on the same nodes to check up on pod anti-affinity scheduling against sharing nodes

Takes an ERE regex argument for deployments / statefulsets to check (use \".\" or leave blank to check all of them)

Subsequent arguments are passed straight to kubectl to be able to specify namespaces, labels etc.

To check for any colocated placements of any deployments or statefulsets across all namespaces:

    ${0##*/} . --all-namespaces
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<deployment_or_statefulset_regex>] [<kubectl_options]>"

help_usage "$@"

#min_args 1 "$@"

regex="${1:-.}"
shift || :

if is_mac; then
    # use GNU uniq to get the -D switch to print all repeated lines
    uniq(){
        guniq "$@"
    }
fi

for x in deploy sts; do
    kubectl get "$x" "$@" -o name |
    grep -E "$regex" |
    sed 's|.*\/||' |
    while read -r name; do
        # awk strips the last 2 cols, adds 1st column namespace to end so uniq can check it too
        # sort by the node column 8
        # show lines with duplicate by node
        # strip last column which is duplicate of namespace column
        kubectl get po "$@" -o wide |
        grep -E "^[^[:space:]]+[[:space:]]+$name-[[:alnum:]]+-[[:alnum:]]+[[:space:]]" |
        awk 'NF{NF-=2}; {print $0" "$1}' |
        column -t |
        sort -k8 |
        uniq -f7 -D |
        awk 'NF{NF-=1}1'
    done
done
