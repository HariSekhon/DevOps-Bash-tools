#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-09-12 23:58:12 +0100 (Mon, 12 Sep 2022)
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
Finds all AWS SSO permission set references in ./*.tf code not in Terraform state and imports them

Determines the permission set ARNs via AWS CLI and then runs the terraform import command

If \$TERRAFORM_PRINT_ONLY is set to any value, prints the commands to stdout to collect so you can check, collect into a text file or pipe to a shell or further manipulate, ignore errors etc.

Caveat: takes the first AWS SSO instance arn found unless \$AWS_SSO_INSTANCE_ARN is explicitly specified in the environment


Requires Terraform and AWS CLIv2 to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

dir="${1:-.}"

cd "$dir"

# terraform plan -out plan.zip
#terraform show -json plan.zip | jq -r '.configuration.root_module.resources[] | select(.type == "aws_ssoadmin_permission_set") | [.address, .expressions.name.constant_value] | @tsv'

#timestamp "getting terraform state"
#terraform_state_list="$(terraform state list)"
#echo >&2
#
#timestamp "determining AWS SSO instance arn"
## XXX: assumes only 1 instance
instance_arn="${AWS_SSO_INSTANCE_ARN:-$(aws sso-admin list-instances | jq -r '.Instances[0].InstanceArn')}"
echo >&2

timestamp "getting AWS permission set list"
permset_arns="$(aws sso-admin list-permission-sets --instance-arn "$instance_arn" | jq -r '.PermissionSets[]')"
echo >&2

# XXX: for Bash 3 portability on Macs, not using associative arrays which aren't available, so building a string map as a workaround
permset_map=""

# XXX: single pass to generate map is better than iterating all permsets for each permset ie. O(n) + O(p) vs O(n * p)
timestamp "Mapping permset ARNs"
echo >&2
for permset_arn in $permset_arns; do
    timestamp "Mapping permset '$permset_arn'"
    name="$(
        aws sso-admin describe-permission-set --instance-arn "$instance_arn" --permission-set-arn "$permset_arn" |
        jq -r '.PermissionSet.Name'
    )"
    if [ -z "$name" ]; then
        die "Failed to resolve name for permset arn '$permset_arn'"
    fi
    permset_map+="
$permset_arn $name
"
    timestamp "Mapped permset '$name'"
done
echo >&2

#timestamp "getting permission sets from $PWD/*.tf code"
#grep -E '^[[:space:]]*resource[[:space:]]+"aws_ssoadmin_permission_set"' -- *.tf |
#awk '{gsub("\"", "", $3); print $3}' |
#while read -r permset; do
#    echo >&2
#    if grep -q "aws_ssoadmin_permission_set\\.$permset$" <<< "$terraform_state_list"; then
#        timestamp "permission set '$permset' already in terraform state, skipping..."
#        continue
#    fi
#    timestamp "Permission set '$permset' needs importing"
#    timestamp "Determining permission set name for '$permset'"
#    set +o pipefail
#    name="$(
#        grep -Eh -A 10 '^[[:space:]]*resource[[:space:]]+"aws_ssoadmin_permission_set"[[:space:]]+"'"$permset"'"' -- *.tf |
#        awk '/^[[:space:]]+name[[:space:]]+=/ {print $3; exit}' |
#        sed 's/"//g'
#    )"
#    set -o pipefail
#    if [ -z "$name" ]; then
#        die "Failed to determine name for permission set '$permset'"
#    fi
#    timestamp "Determined permission set name for '$permset' to be '$name'"
#    timestamp "Determining ARN for permission set '$name'"
#    # XXX: string map workaround for Bash 3
#    permset_arn="$(awk "/[[:space:]]${name//\//\\/}$/"' {print $1}' <<< "$permset_map")"
#    if [ -z "$permset_arn" ]; then
#        die "Failed to determine permission set arn for '$name'"
#    fi
#    timestamp "Importing permission set '$permset'"
#    cmd="terraform import \"aws_ssoadmin_permission_set.$permset\" \"$permset_arn,$instance_arn\""
#    echo "$cmd"
#    if [ -z "${TERRAFORM_PRINT_ONLY:-}" ]; then
#        eval "$cmd"
#    fi
#    echo >&2
#done

terraform plan -no-color |
sed -n '/# aws_ssoadmin_permission_set\..* will be created/,/name/ p' |
awk '/# aws_ssoadmin_permission_set/ {print $2};
     /instance_arn|name/ {print $4}' |
sed 's/^"//; s/"$//' |
xargs -n3 echo |
sed 's/\[/["/; s/\]/"]/' |
while read -r id instance_arn name; do
    [ -n "$name" ] || continue
    timestamp "Determining permset arn from name '$name'"
    timestamp "Determining ARN for permission set '$name'"
    # XXX: string map workaround for Bash 3
    permset_arn="$(awk "/[[:space:]]${name//\//\\/}$/"' {print $1}' <<< "$permset_map")"
    if [ -z "$permset_arn" ]; then
        die "Failed to resolve permset arn for '$name'"
    fi
    timestamp "Importing $name"
    cmd=(terraform import "$id" "$permset_arn,$instance_arn")
    timestamp "${cmd[*]}"
    if [ -z "${TERRAFORM_PRINT_ONLY:-}" ]; then
        "${cmd[@]}"
    fi
    echo >&2
done
