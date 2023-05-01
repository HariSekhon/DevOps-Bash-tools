#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-18 11:09:30 +0000 (Wed, 18 Nov 2020)
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

# shellcheck disable=SC1090,SC1091
# not using anything from here directly
#. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs kubectl diff and apply, prompting to accept any changes before applying

Must be given kubectl args to provide the input yaml(s), eg:

    ${0##*/} -f file.yaml

    kustomize build | ${0##*/} -f -

Highly recommended to specify --context to avoid race conditions in global kube config which could apply to the wrong cluster. See kubectl.sh for more details

    ${0##*/} -f file.yaml --context=gke_...

See Also:

    kustomize_diff_apply.sh - runs kustomize build, precreates namespaces, and then runs this diff and apply

    kubectl_create_namespaces.sh - creates any namespaces in the yaml inputs to allow an initial diff to succeed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<kubectl_options>"

help_usage "$@"

stdin=0
yaml=""

# there is no space before -f in $* if given as first argument
#if [[ "$*" =~ [[:space:]]-f[[:space:]]*- ]]; then
if [[ "$*" =~ -f[[:space:]]*- ]]; then
    stdin=1
fi

if [ $stdin -eq 1 ]; then
    yaml="$(cat)"
fi

echo "Diff from live running cluster:"
echo

if kubectl diff "$@" <<< "$yaml"; then
    echo "No changes to deploy"
    exit 0
fi

echo
read -r -p "Deploy the above changes? (y/N) " answer < /dev/tty  # < $(tty)
shopt -s nocasematch
if [[ ! "$answer" =~ ^y|yes$ ]]; then
    echo "Aborting..."
    exit 1
fi
shopt -u nocasematch
echo
echo

kubectl apply "$@" <<< "$yaml"
