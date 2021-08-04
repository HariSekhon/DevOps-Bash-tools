#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-18 11:09:30 +0000 (Wed, 18 Nov 2020)
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
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
# not using anything from here directly
#. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs kustomize build, precreates any namespaces, prompts you with a diff to the changes, and then applies if you accept the prompt

Must be run from the Kustomize directory

Uses adjacent scripts:

    kubectl_diff_apply.sh
    kubectl_create_namespaces.sh

If a kubectl context is given as an arg, uses adjacent kubectl.sh to prevent race conditions, see kubectl.sh for more details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<kubectl_context> <kubectl_options>"

help_usage "$@"

context="${1:-}"
shift || :

if [ -n "$context" ]; then
    kube_config_isolate
    kube_context "$context"
fi

echo "Deploying Kustommize kubernetes configs from directory: $PWD"
echo

yaml="$(kustomize build)"

echo "Pre-creating any namespaces so that diff can succeed"
"$srcdir/kubectl_create_namespaces.sh" <<< "$yaml"

"$srcdir/kubectl_diff_apply.sh" -f - <<< "$yaml"

#echo "Diff from live running cluster:"
#echo
#
#if kubectl diff -f - <<< "$yaml"; then
#    echo "No changes to deploy"
#    exit 0
#fi
#
#echo
#read -r -p "Deploy the above changes? (y/N) " answer
#shopt -s nocasematch
#if [[ ! "$answer" =~ ^y|yes$ ]]; then
#    echo "Aborting..."
#    exit 1
#fi
#shopt -u nocasematch
#echo
#echo
#
#kubectl apply -f - "$@" <<< "$yaml"
