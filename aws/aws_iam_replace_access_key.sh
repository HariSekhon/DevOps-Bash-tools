#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-13 22:40:11 +0000 (Mon, 13 Dec 2021)
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
Creates a new IAM access key for the currently authenticated user, outputting the keys as export commands

If 2 keys already exist, decide which key to replace using these heuristics in this order of preference:

- inactive key
- unused key
- oldest usage (ie. not the key we're currently using to authenticate)

Alternatively you can specify an access key id to delete as an argument, but if there is only 1 access key it won't delete it for safety (will output warning)

If there is only 1 access key, a 2nd key is created but no key is deleted for safety to prevent you cutting yourself off as standard usage is to rotate through 2 access keys

If the first argument given starts with a dash it is inferred to be an AWS CLI option instead of an access key ID to replace and the above heuristic is used to figure out which key to replace


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_access_key_id> <aws_cli_options>]"

help_usage "$@"

#min_args 1 "$@"

access_key_id_to_delete=""
if ! [[ "${1:-}" =~ ^- ]]; then
    access_key_id_to_delete="${1:-}"
    if [ $# -gt 0 ]; then
        shift || :
    fi
fi

export AWS_DEFAULT_OUTPUT=json

keys="$(aws iam list-access-keys "$@")"

num_keys="$(jq -r '.AccessKeyMetadata | length' <<< "$keys")"
if ! [[ "$num_keys" =~ ^[[:digit:]]+$ ]]; then
    die "Failed to determine number of AWS access keys"
fi

# Limited to 2 access keys
if [ "$num_keys" -gt 2 ]; then
    die "More than 2 access keys found - code error or AWS has changed the limitations, which affects this logic and requires a code update"
elif [ "$num_keys" -eq 2 ]; then
    if [ -z "$access_key_id_to_delete" ]; then
        # figure out which one to delete
        access_key_ids="$(jq -r '.AccessKeyMetadata[].AccessKeyId' <<< "$keys")"
        last_key_last_used_date=""
        for access_key_id in $access_key_ids; do
            key_status="$(jq -r ".AccessKeyMetadata[] | select(.AccessKeyId == \"$access_key_id\") | .Status" <<< "$keys")"
            if [ "$key_status" = "Inactive" ]; then
                access_key_id_to_delete="$access_key_id"
                break
            fi
            # not passing "$@" because if --user-name is specified it is only relevant to other commands
            last_used_date="$(aws iam get-access-key-last-used --access-key-id "$access_key_id" |
                              jq -r '.AccessKeyLastUsed.LastUsedDate')"
            if [ "$last_used_date" = null ]; then
                access_key_id_to_delete="$access_key_id"
                break
            fi
            # XXX: Ugly, improve logic here
            if [ -n "$last_key_last_used_date" ]; then
                # convert both last used to epoch, smaller number is older
                if [ "$(date '+%s' --date "$last_used_date")" -le "$(date '+%s' --date "$last_key_last_used_date")" ]; then
                    access_key_id_to_delete="$access_key_id"
                else
                    # first key must be older
                    access_key_id_to_delete="$(jq -r '.AccessKeyMetadata[0].AccessKeyId' <<< "$keys")"
                fi
                break
            fi
            last_key_last_used_date="$last_used_date"
        done
    fi
    if [ -z "$access_key_id_to_delete" ]; then
        die "Couldn't determine which access key to delete, aborting..."
    fi
    timestamp "Deleting AWS access key '$access_key_id_to_delete'"
    #aws iam update-access-key --access-key-id "$access_key_id_to_delete" --status Inactive
    aws iam delete-access-key --access-key-id "$access_key_id_to_delete" "$@"
    echo >&2
fi

aws iam create-access-key "$@" |
jq -r '
    .AccessKey |
    [ "export AWS_ACCESS_KEY_ID=" + .AccessKeyId, "export AWS_SECRET_ACCESS_KEY=" + .SecretAccessKey ] |
    join("\n")
'
