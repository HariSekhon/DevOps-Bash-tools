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

# shellcheck disable=SC1090,SC1091
. "$libdir/utils.sh"

# used in client scripts
# shellcheck disable=SC2034
usage_aws_cli_required="Requires AWS CLI to be installed and configured (run 'make aws && aws configure')"
# shellcheck disable=SC2034
usage_aws_cli_jq_required="Requires AWS CLI to be installed and configured, as well as jq  (run 'make aws && aws configure')"

# shortest AWS Region length is 9 for eu-west-N
#
#   aws ec2 describe-regions --query "Regions[].{Name:RegionName}" --output text |
#   awk '{ if (length < min || NR == 1) min = length } END { print min }'
#
aws_ecr_regex='[[:digit:]]{12}.dkr.ecr.[[:alnum:]-]{9,}.amazonaws.com'
aws_account_id_regex='[[:digit:]]{12}'
aws_region_regex='[a-z]{2}-[a-z]+-[[:digit:]]'
instance_id_regex='i-[0-9a-fA-F]{17}'
ami_id_regex='ami-[0-9a-fA-F]{8}([0-9a-fA-F]{9})?'
# S3 URL regex with s3:// prefix
s3_regex='s3:\/\/([a-z0-9][a-z0-9.-]{1,61}[a-z0-9])\/(.+)$|^s3:\/\/([a-z0-9][a-z0-9.-]{1,61}[a-z0-9])\/([a-z0-9][a-z0-9.-]{1,61}[a-z0-9])\/(.+)'
aws_sg_regex="sg-[0-9a-f]{8,17}"
aws_subnet_regex="subnet-[0-9a-f]{8,17}"

is_aws_sso_logged_in(){
    aws sts get-caller-identity &>/dev/null
}

aws_account_id(){
    aws sts get-caller-identity --query Account --output text
}

aws_account_name(){
    # you may not have permission to the AWS Org in which case this will return an error:
    #
    #   An error occurred (AccessDeniedException) when calling the DescribeAccount operation: You don't have permissions to access this resource.
    #
    aws organizations describe-account --account-id "$AWS_ACCOUNT_ID" --query "Account.Name" --output text
}

aws_region(){
    # region actually used by the CLI, but some accounts running scripts may not have permissions to this
    # aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]'
    if [ -n "${AWS_DEFAULT_REGION:-}" ]; then
        echo "$AWS_DEFAULT_REGION"
        return
    fi
    region="$(aws configure get region || :)"
    if [ -z "$region" ]; then
        region="$(aws ec2 describe-availability-zones --query "AvailabilityZones[0].RegionName" --output text || :)"
    fi
    if [ -z "$region" ]; then
        die "FAILED to get AWS region in aws_region() function in lib/aws.sh"
    fi
    if ! is_aws_region "$region"; then
        die "Invalid AWS Region returned in lib/aws.sh, failed regex validation: $region"
    fi
    echo "$region"
}

aws_ecr_registry(){
    local aws_ecr_registry="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
    if ! is_aws_ecr_registry "$aws_ecr_registry"; then
        die "Failed to generated AWS ECR registry correctly, failed regex: $aws_ecr_registry"
    fi
    echo "$aws_ecr_registry"
}

is_aws_ecr_registry(){
    local arg="$1"
    [[ "$arg" =~ ^$aws_ecr_regex$ ]]
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

# returns one cluster name per line
aws_eks_clusters(){
    aws eks list-clusters --query 'clusters' --output text |
    tr '[:space:]' '\n' |
    sed '/^[[:space:]]*$/d'
}

aws_eks_cluster_if_only_one(){
    local eks_clusters
    eks_clusters="$(aws_eks_clusters)"
    num_eks_clusters="$(grep -c . <<< "$eks_clusters")"
    if [ "$num_eks_clusters" = 1 ]; then
        echo "$eks_clusters"
    fi
}

aws_validate_volume_id(){
    local volume_id="$1"
    if ! [[ "$volume_id" =~ ^vol-[[:alnum:]]{17}$ ]]; then
        usage "
    Invalid volume ID given, expected format: vol-xxxxxxxxxxxxxxxxx,
                                   but given: $volume_id"
    fi
}

aws_sso_login_if_not_already(){
    if ! is_aws_sso_logged_in; then
        # output to stderr so that if we are collecting the output from this script,
        # we do not collect any output from sso login
        aws sso login 2>&1
    fi
}

aws_sso_cache(){
    # find is not as good for finding the sorted latest cache file
    # shellcheck disable=SC2012
    ls -t ~/.aws/sso/cache/*.json | head -n1
}

aws_sso_token(){
    local sso_cache_file
    sso_cache_file="$(aws_sso_cache)"
    jq -r .accessToken < "$sso_cache_file"
}

aws_sso_role(){
    role="${AWS_DEFAULT_ROLE:-${AWS_ROLE:-${ROLE:-}}}"
    if ! is_blank "$role"; then
        log "Using role from environment variable: $role"
        echo "$role"
    else
        log "Determining role from currently authenticated AWS SSO role"
        role="$(
        aws sts get-caller-identity --query Arn --output text |
        sed '
            s|^arn:aws:sts:.*:assumed-role/AWSReservedSSO_||;
            s|_[[:alnum:]]\{16\}/.*$||;
        '
    )"
        log "Determined role to be: $role"
        echo "$role"
    fi
}

aws_sso_start_url(){
    local sso_start_url
    log "Determining SSO Start URL"
    sso_start_url="$(aws configure get sso_start_url || :)"
    if is_blank "$sso_start_url"; then
        # shouldn't fall through to this
        log "Failed to determine SSO Start URL from 'aws configure', falling back to trying the highest occurence in sso cache file"
        local sso_cache_file
        sso_cache_file="$(aws_sso_cache)"
        sso_start_url="$(
            jq -Mr '.startUrl' "$sso_cache_file" |
            sed '/^null$/d' |
            sort |
            uniq -c |
            sort -nr |
            awk '{print \$2; exit}'
        )"
    fi
    if ! is_url "$sso_start_url"; then
        die "Invalid AWS SSO Start URL returned in lib/aws.sh, failed regex validation: $sso_start_url"
    fi
    log "Determined SSO Start URL: $sso_start_url"
    echo "$sso_start_url"
}

aws_sso_start_region(){
    log "Determining SSO Start Region from config"
    local sso_cache_file
    sso_cache_file="$(aws_sso_cache)"
    local sso_start_region
    sso_start_region="$(jq -Mr '.region' "$sso_cache_file")"
    if ! is_aws_region "$sso_start_region"; then
        die "Invalid AWS SSO Start Region returned, failed regex validation: $sso_start_region"
    fi
    log "Determined SSO Start Region: $sso_start_region"
    echo "$sso_start_region"
}

aws_region_from_env(){
    local region
    region="${AWS_DEFAULT_REGION:-${AWS_REGION:-${REGION:-}}}"
    if ! is_blank "$region"; then
        log "Using region from environment variable: $region"
    else
        region="$(aws_region)"
        if ! is_blank "$region"; then
            log "Inferred region to be: $region"
        elif ! is_blank "${aws_default_region:-}"; then
            region="$aws_default_region"
            log "Defaulting to using region: $region"
        else
            echo "AWS region not found from environment variables or AWS mechanism" >&2
            return 1
        fi
    fi
    if ! is_aws_region "$region"; then
        die "Invalid AWS region, failed regex validation: $region"
    fi
    echo "$region"
}

is_aws_account_id(){
    local arg="$1"
    [[ "$arg" =~ ^$aws_account_id_regex$ ]]
}

is_aws_region(){
    local arg="$1"
    [[ "$arg" =~ ^$aws_region_regex$ ]]
}

is_s3_url(){
    local arg="$1"
    [[ "$arg" =~ ^$s3_regex$ ]]
}

is_instance_id(){
    local arg="$1"
    [[ "$arg" =~ ^$instance_id_regex$ ]]
}
is_ami_id(){
    local arg="$1"
    [[ "$arg" =~ ^$ami_id_regex$ ]]
}

aws_validate_ami_id() {
    local arg="$1"
    if ! is_instance_id "$arg"; then
        die "Invalid EC2 AMI ID: $arg"
    fi
}

aws_validate_instance_id() {
    local arg="$1"
    if ! is_instance_id "$arg"; then
        die "Invalid EC2 Instance ID: $arg"
    fi
}

aws_validate_security_group_id() {
    local arg="$1"
    if ! is_aws_security_group_id "$arg"; then
        die "Invalid Security Group ID: $arg"
    fi
}

is_aws_security_group_id() {
    local arg="$1"
    [[ "$arg" =~ ^$aws_sg_regex$ ]]
}

aws_validate_subnet_id() {
    local arg="$1"
    if ! is_aws_subnet_id "$arg"; then
        die "Invalid Subnet ID: $arg"
    fi
}

is_aws_subnet_id() {
    local arg="$1"
    [[ "$arg" =~ ^$aws_subnet_regex$ ]]
}

#aws_get_cred_path(){
#    # unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
#    [ -n "${HOME:-}" ] || HOME=~
#    local aws_credentials="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
#    local aws_config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
#    local boto="${BOTO_CONFIG:-$HOME/.boto}"
#    local credentials_file
#    if [ -f "$aws_credentials" ]; then
#        credentials_file="$aws_credentials"
#    # older boto creds
#    elif [ -f "$boto" ]; then
#        credentials_file="$boto"
#    elif [ -f "$aws_config" ]; then
#        credentials_file="$aws_config"
#    else
#        echo "no credentials found - didn't find $aws_credentials or $boto or $aws_config" 2>/dev/null
#        return 1
#    fi
#    echo "$credentials_file"
#}
#aws_credentials_file="$(aws_get_cred_path)"
