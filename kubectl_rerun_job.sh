#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-06 09:10:40 +0000 (Thu, 06 Jan 2022)
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
Backups up and then re-runs a given Kubernetes job

Backups are taken to the source directory of this script under the .kubectl_job_definitions/ directory before re-creating the job,
just in case, as a delete operation must happen before the re-creation and if the re-creation fails the job definition would otherwise be lost

Example:

    ${0##*/} cert-manager-startupapicheck -n cert-manager
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<job_name> [<kubectl_options>]"

help_usage "$@"

min_args 1 "$@"

job_name="$1"
shift || :

namespace=""
args=()

until [ $# -lt 1 ]; do
    case $1 in
      -n|--namespace)  namespace="${2:-}"
                       shift || :
                       ;;
                   *)  args+=("$1")
                       ;;
    esac
    shift || :
done

# if namespace was not set then try to infer from current context
if [ -z "$namespace" ]; then
    namespace="$(kubectl config get-contexts | awk '/^\*/{print $5}')"
fi
# if not set in context, must be 'default'
namespace="${namespace:-default}"

#jobdir="${PWD:-$(pwd)}/.kubectl_job_definitions"
jobdir="$srcdir/.kubectl_job_definitions"
mkdir -p -v "$jobdir"

jobfile="$jobdir/$namespace.$job_name.json"

# backup the job because job recreation will fail after it is deleted if any of the fields prevent re-creation
# remove the fields that prevent recreation
if ! [ -f "$jobfile" ]; then
    kubectl get job "$job_name" ${namespace:+--namespace "$namespace"} ${args:+"${args[@]}"} -o json |
    jq -Mr 'del(.spec.selector)' |
    jq -Mr 'del(.spec.template.metadata.labels)' \
    > "$jobfile"
fi

kubectl replace --force -f "$jobfile"
