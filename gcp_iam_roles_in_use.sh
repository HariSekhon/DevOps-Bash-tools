#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-12 14:13:44 +0000 (Fri, 12 Feb 2021)
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
Quick list of unique project-level GCP IAM roles in use in the current GCP project or across all projects

Useful for quick lookups of IAM policy role names which are different from the human readable names in the GCP UI

eg. when backporting GCP IAM permissions to Terraform:

    gcloud projects get-iam-policy \"\$(gcloud config list --format='get(core.project)')\" > /tmp/iam_policy.yaml
    ${0##*/} > /tmp/iam_roles_reference.txt
    vim -O /tmp/iam_policy.yaml /tmp/iam_roles_reference.txt
    # in another window edit the Terraform IAM and screen/tmux back and forth from this reference


NOTICE: does not include roles assigned to say individual GCS buckets, only those assigned at the project level to users, groups or serviceAccounts.


You can optionally specify the GCP project, otherwise infers your currently set core.project

If you specify 'all' for project, will return a sorted superset list from all projects

If the role you're looking for isn't currently in use, you may want to browse all role names in SDK format for use in Terraform via:

  gcloud iam roles list --format='get(name)'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

#min_args 1 "$@"

project="${1:-}"

if is_blank "$project"; then
    project="$(gcloud config list --format='get(core.project)')"
fi

not_blank "$project" || die "ERROR: no project specified and GCloud SDK core.project property not set in config"

get_roles(){
    local project="$1"
    gcloud projects get-iam-policy "$project" --format=json |
    #awk '/^[[:space:]]+role:[[:space:]]/{print $2}'
    jq -r '.bindings[].role'
}

if [ "$project" = "all" ] ;then
    for project in $(gcloud projects list --format='get(project_id)'); do
        get_roles "$project"
    done
else
    get_roles "$project"
fi |
sort -u
