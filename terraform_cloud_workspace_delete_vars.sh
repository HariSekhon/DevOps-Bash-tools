#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: :workspace haritest
#
#  Author: Hari Sekhon
#  Date: 2021-12-21 13:30:39 +0000 (Tue, 21 Dec 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://www.terraform.io/cloud-docs/api-docs/workspace-variables

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes one or more variables in a given Terraform Cloud workspace

See terraform_cloud_organizations.sh to get a list of organization IDs
See terraform_cloud_varsets.sh to get a list of workspaces and their IDs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<workspace_id> <variable_name> [<variable_name2> ...]"

help_usage "$@"

min_args 2 "$@"

workspace_id="$1"
shift || :

if [ -z "$workspace_id" ]; then
    usage "no terraform workspace id given"
fi

"$srcdir/terraform_cloud_workspace_vars.sh" "$workspace_id" |
while read -r id _ _ name _; do
    for var in "$@"; do
        if [ "$var" = "$name" ]; then
            timestamp "deleting variable '$name' (id '$id') in workspace id '$workspace_id'"
            "$srcdir/terraform_cloud_api.sh" "/workspaces/$workspace_id/vars/$id" -X DELETE
        fi
    done
done
