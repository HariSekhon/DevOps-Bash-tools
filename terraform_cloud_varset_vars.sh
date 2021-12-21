#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args:
#  args: :organization
#
#  Author: Hari Sekhon
#  Date: 2021-12-21 13:30:39 +0000 (Tue, 21 Dec 2021)
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists Terraform Cloud variables in all variable sets for a given organiztion

\$TERRAFORM_ORGANIZATION and \$TERRAFORM_VARSET_ID can be used instead of arguments

Output:

<varset_id>     <varset_name>   <id>    <type>      <name>      <value>
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<organization> <varset_id>]"

help_usage "$@"

#min_args 1 "$@"

org="${1:-${TERRAFORM_ORGANIZATION:-}}"
varset_id="${2:-${TERRAFORM_VARSET_ID:-}}"

if [ -z "$org" ]; then
    usage "no terraform organization given and TERRAFORM_ORGANIZATION not set"
fi

# XXX: TODO: add pagination if > 1 page of varsets
if [ -n "$varset_id" ]; then
    variable_sets="$("$srcdir/terraform_cloud_api.sh" "organizations/$org/varsets/$varset_id" | jq -r '.data[] | [.id, .attributes.name] | @tsv')"
else
    variable_sets="$("$srcdir/terraform_cloud_api.sh" "organizations/$org/varsets" | jq -r '.data[] | [.id, .attributes.name] | @tsv')"
fi

while read -r varset_id varset_name; do
    # XXX: TODO: add pagination if > 1 page of variables
    "$srcdir/terraform_cloud_api.sh" "/varsets/$varset_id/relationships/vars"  |
    jq -r ".data[] | [\"$varset_id\", \"$varset_name\", .id, .attributes.category, .attributes.key, .attributes.value] | @tsv" |
    column -t
done <<< "$variable_sets"
