#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-01 15:51:36 +0100 (Tue, 01 Sep 2020)
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
For all or a given list of instances in the current GCP project, list the instance names and their service accounts

GCloud SDK is required, and will attempt to infer the zone based on the instance name, but sometimes it cannot, in
which cases you advised to set the compute/zone yourself (gcloud config set compute/zone ...)

Caveat: slow - would write a Python version but the API is so bad and hardly documented that it's not worth the trouble
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<instances>]"

help_usage "$@"

#min_args 1 "$@"

list_vm_service_account(){
    local instance="$1"
    local zone="${2:-}"
    local opts=()
    if [ -n "$zone" ]; then
        opts+=(--zone "$zone")
    fi
    # outputs the results to stderr when no zone is specified
    gcloud compute instances describe "$instance" "${opts[@]}" --format='table[no-heading](name, serviceAccounts.email.join(","))' 2>&1 #|
    # GCloud SDK changes behaviour to error out if piped!
    #grep -Ev '^No zone specified. Using zone \[[[:alnum:]-]+\] for instance:' || :
}

if [ $# -gt 0 ]; then
    for arg; do
        list_vm_service_account "$arg"
    done
else
    gcloud compute instances list --format='table[no-heading](name, serviceAccounts.email.join(","))'
fi
