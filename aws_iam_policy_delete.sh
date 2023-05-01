#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-15 18:41:42 +0100 (Wed, 15 Jun 2022)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Deletes an IAM policy by first handling all prerequisite steps of deleting all prior versions and detaching all users, groups and roles

Because doing a straight delete will fail with an error like this:

    An error occurred (DeleteConflict) when calling the DeletePolicy operation: This policy has more than one version. Before you delete a policy, you must delete the policy's versions. The default version is deleted with the policy.

or this:

    An error occurred (DeleteConflict) when calling the DeletePolicy operation: Cannot delete a policy attached to entities.
"

help_usage "$@"

min_args 1 "$@"

policy="$1"

export AWS_DEFAULT_OUTPUT=json

aws_account_id="$(aws_account_id)"

policy_arn="arn:aws:iam::$aws_account_id:policy/$policy"

detach_entity(){
    local entity_type="$1"
    local entity="$2"
    entity_type="$(tr '[:upper:]' '[:lower:]' <<< "$entity_type")"
    timestamp "Detaching $entity_type $entity"
    aws iam "detach-${entity_type}-policy" "--${entity_type}-name" "$entity" --policy-arn "$policy_arn"
}

detach_entities(){
    local entity_type="$1"
    aws iam list-entities-for-policy --policy-arn "$policy_arn" |
    jq -r ".Policy${entity_type}s[].${entity_type}Name" |
    while read -r entity; do
        detach_entity "$entity_type" "$entity"
    done
}

older_policy_versions="$(aws iam list-policy-versions --policy-arn "$policy_arn" |
                         jq -r '.Versions[] | select(.IsDefaultVersion == false) | .VersionId')"

for policy_version_id in $older_policy_versions; do
    timestamp "Deleting policy '$policy' version '$policy_version_id'"
    aws iam delete-policy-version --policy-arn "$policy_arn" --version-id "$policy_version_id"
done

detach_entities User
detach_entities Group
detach_entities Role

timestamp "Deleting policy '$policy'"
aws iam delete-policy --policy-arn "$policy_arn"
timestamp "Done"
