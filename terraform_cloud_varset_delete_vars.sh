#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: :organization $TERRAFORM_VARSET_ID haritest
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

# https://www.terraform.io/cloud-docs/api-docs/variable-sets

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes one or more variables in a given Terraform Cloud variable set id

See terraform_cloud_organizations.sh to get a list of organization IDs
See terraform_cloud_varsets.sh to get a list of variable sets and their IDs
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<organization> <varset_id> <variable_name> [<variable_name2> ...]"

help_usage "$@"

min_args 3 "$@"

org="$1"
varset_id="$2"
shift || :
shift || :

if [ -z "$varset_id" ]; then
    usage "no terraform varset id given"
fi

"$srcdir/terraform_cloud_varset_vars.sh" "$org" "$varset_id" |
while read -r varset_id varset_name id _ _ name _; do
    for var in "$@"; do
        if [ "$var" = "$name" ]; then
            timestamp "deleting variable '$name' (id '$id') in varset '$varset_name' (id '$varset_id')"
            "$srcdir/terraform_cloud_api.sh" "/varsets/$varset_id/relationships/vars/$id" -X DELETE
        fi
    done
done
