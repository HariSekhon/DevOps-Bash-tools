#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 13:53:11 +0000 (Fri, 11 Dec 2020)
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
libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$libdir/utils.sh"

# used in client scripts
# shellcheck disable=SC2034
usage_aws_cli_required="AWS CLI is required to be installed and configured, as well as jq  (run 'make aws && aws configure')"

aws_account_id(){
    aws sts get-caller-identity --query Account --output text
}

aws_region(){
    # region actually used by the CLI, but some accounts running scripts may not have permissions to this
    # aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]'
    if [ -n "${AWS_DEFAULT_REGION:-}" ]; then
        echo "$AWS_DEFAULT_REGION"
        return
    fi
    if ! aws configure get region; then
        echo "FAILED to get AWS region in aws_region() function in lib/aws.sh" >&2
        return 1
    fi
}

aws_user_exists(){
    local user="$1"
    aws iam list-users | jq -e -r ".Users[] | select(.UserName == \"$user\")" >/dev/null
}

aws_create_user_if_not_exists(){
    local user="$1"
    if aws_user_exists "$user"; then
        timestamp "User '$user' already exists"
    else
        timestamp "Creating user '$user'"
        aws iam create-user --user-name "$user"
    fi
}

aws_create_access_key_if_not_exists(){
    local user="$1"
    local access_keys_csv="$2"
    mkdir -pv "$(dirname "$access_keys_csv")"
    if [ -f "$access_keys_csv" ] && grep -Fq AKIA "$access_keys_csv"; then
        timestamp "Access Keys CSV '$access_keys_csv' already exists"
        "$libdir/../aws/aws_csv_creds.sh" "$access_keys_csv"
    else
        local exports
        timestamp "Creating access key, removing an old one if necessary"
        exports="$("$libdir/../aws/aws_iam_replace_access_key.sh" --user-name "$user")"
        aws_access_keys_to_csv <<< "$exports" >> "$access_keys_csv"
        timestamp "Created access key and saved to CSV:  $access_keys_csv"
        echo "$exports"
    fi
}

# reads export commands and outputs CSV file format to stdout to save
aws_access_keys_to_csv(){
    local env_var
    local access_key
    local secret_key
    while read -r line; do
        is_blank "$line" && continue
        env_var="${line%%#*}"
        env_var="${env_var##[[:space:]]}"
        env_var="${env_var##export}"
        env_var="${env_var##[[:space:]]}"
        if ! [[ "$env_var" =~ ^[[:alpha:]][[:alnum:]_]+=.+$ ]]; then
            die "invalid environment key=value argument passed to aws_access_keys_to_csv(): $env_var"
        fi
        key="${env_var%%=*}"
        value="${env_var#*=}"
        if [ "$key" = "AWS_ACCESS_KEY_ID" ]; then
            access_key="$value"
        elif [ "$key" = "AWS_SECRET_ACCESS_KEY" ]; then
            secret_key="$value"
        else
            die "unexpected key '$key' passed to aws_access_keys_to_csv() - only expected AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY"
        fi
    done
    if is_blank "$access_key"; then
        die "aws_access_keys_to_csv(): failed to parse access key"
    fi
    if is_blank "$secret_key"; then
        die "aws_access_keys_to_csv(): failed to parse secret key"
    fi
    echo "Access key ID,Secret access key"  # header line to match the AWS console UI
    echo "$access_key,$secret_key"
}

# reads export commands and outputs ~/aws/credentials file format to stdout to save
aws_access_keys_exports_to_credentials(){
    local profile="${AWS_PROFILE:-default}"
    local env_var
    local key
    local value
    echo "[$profile]"
    while read -r line; do
        is_blank "$line" && continue
        env_var="${line%%#*}"
        env_var="${env_var##[[:space:]]}"
        env_var="${env_var##export}"
        env_var="${env_var##[[:space:]]}"
        if ! [[ "$env_var" =~ ^[[:alpha:]][[:alnum:]_]+=.+$ ]]; then
            die "invalid environment key=value argument passed to aws_access_keys_exports_to_credentials(): $env_var"
        fi
        key="${env_var%%=*}"
        value="${env_var#*=}"
        echo "$(tr '[:upper:]' '[:lower:]' <<< "$key")=$value"
    done
}
