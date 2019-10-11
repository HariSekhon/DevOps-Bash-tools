#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2012-09-01 13:01:11 +0100
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                A W S  -  A m a z o n   W e b   S e r v i c e s
# ============================================================================ #

srcdir="${srcdir:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
type add_PATH &>/dev/null || . "$srcdir/.bash.d/paths.sh"

# JAVA_HOME needs to be set to use EC2 api tools
#[ -x /usr/bin/java ] && export JAVA_HOME=/usr  # errors but still works

# link_latest '/usr/local/ec2-api-tools-*'
if [ -d /usr/local/ec2-api-tools ]; then
    export EC2_HOME=/usr/local/ec2-api-tools   # this should be a link to the unzipped ec2-api-tools-1.6.1.4/
    add_PATH "$EC2_HOME/bin"
fi

# ec2dre - ec2-describe-regions - list regions you have access to and put them here
# TODO: pull a more recent list and have aliases/functions auto-generated from that to export
aws_eu(){
    export EC2_URL=ec2.eu-west-1.amazonaws.com
}
aws_useast(){
    export EC2_URL=ec2.us-east-1.amazonaws.com
}
#aws_eu

aws_get_cred_path(){
    local aws_credentials=~/.aws/credentials
    local boto=~/.boto
    local credentials_file
    if [ -f "$aws_credentials" ]; then
        credentials_file="$aws_credentials"
    # older boto creds
    elif [ -f "$boto" ]; then
        credentials_file="$boto"
    else
        echo "no credentials found - didn't find $boto or $aws_credentials" 2>/dev/null
        return 1
    fi
    echo "$credentials_file"
}

# this rarely changes so just set it once as initialization instead of passing lots of params
# or re-executing aws_get_cred_path() multiple times in different functions
aws_credentials_file="$(aws_get_cred_path)"

aws_get_profile_data(){
    local profile="$1"
    sed -n "/[[:space:]]*\\[$profile\\]/,/^[[:space:]]*\\[/p" "$aws_credentials_file"
}

aws_profile(){
    local profile="${1// }"
    if [ -n "$profile" ]; then
        if ! [[ "$profile" =~ ^[[:alnum:]_-]+$ ]]; then
            echo "invalid profile name given, must be alphanumeric, dashes and underscores allowed"
            return 1
        fi
        local profile_data
        profile_data="$(aws_get_profile_data "$profile")"
        if [ -z "$profile_data" ]; then
            echo "profile [$profile] not found in $aws_credentials_file!"
            return 1
        fi
        echo "setting aws profile to '$profile'"
        export AWS_PROFILE="$profile"
    elif [ -n "$AWS_PROFILE" ]; then
        echo "$AWS_PROFILE"
    else
        echo "default (keys not loaded to env)"
    fi
}
alias awsprofile=aws_profile

# Storing creds in one place in Boto creds file, pull them straight from there
aws_env(){
    local profile="${1:-default}"
    # export AWS_ACCESS_KEY
    # export AWS_SECRET_KEY
    # export AWS_SESSION_TOKEN - for multi-factor authentication
    local aws_token=~/.aws/token
    aws_profile "$profile" || return 1
    # section is checked for existence as part of aws_profile(), will return before here if not valid
    local profile_data
    profile_data="$(aws_get_profile_data "$profile")"
    echo "loading [$profile] creds from $aws_credentials_file"
    eval "$(
    for key in aws_access_key_id aws_secret_access_key aws_session_token; do
        awk -F= "/^[[:space:]]*$key/"'{gsub(/[[:space:]]+/, "", $0); gsub(/_id/, "", $1); gsub(/_secret_access/, "_secret", $1); print "export "toupper($1)"="$2}' <<< "$profile_data"
    done
    )"
    if [ -f "$aws_token" ]; then
        echo "sourcing $aws_token"
        # shellcheck disable=SC1090
        source "$aws_token"
    fi
}
alias awsenv=aws_env

aws_envs(){
    awk '/^[[:space:]]*\[.+\]/{print $1}' < "$aws_credentials_file" |
    sed 's/\[//;s/\]//' |
    while read profile; do
        default=0
        if [ "$profile" = "$AWS_PROFILE" ]; then
            local default=1
        elif [ -z "$AWS_PROFILE" ] &&
             [ "$profile" = "default" ]; then
            local default=1
        fi
        if [ "$default" = 1 ]; then
            echo -n "* "
        else
            echo -n "  "
        fi
        echo -n "$profile"
        if [ "$default" = 1 ] &&
           ! env | grep -q '^AWS_SECRET_KEY='; then
            echo -n " (keys not loaded to env)"
        fi
        echo
    done
}
alias awsenvs=aws_envs

aws_unenv(){
    unset AWS_ACCESS_KEY
    unset AWS_SECRET_KEY
    unset AWS_SESSION_TOKEN
}
alias awsunenv=aws_unenv

aws_token(){
    local output
    local token
    if [ $# -eq 0 ]; then
        echo "usage: aws_token <token_from_mfa_device> [<other_options>]"
        return 1
    fi
    if [ -z "${AWS_MFA_ARN:-}" ]; then
        echo "environment variable \$AWS_MFA_ARN not set - you need to"
        echo
        echo "export AWS_MFA_ARN=arn:aws:iam::<123456789012>:mfa/<user>"
        echo
        echo "(you might want to put that in your ~/.bashrc.local or similar)"
        return 1
    fi
    #aws sts get-session-token --serial-number arn-of-the-mfa-device --token-code code-from-token
    output="$(aws sts get-session-token --serial-number "$AWS_MFA_ARN" --duration-seconds "${AWS_STS_DURATION_SECS:-129600}" --token-code "$@")"
    result=$?
    echo "$output"
    if [ $result -ne 0 ]; then
        return $result
    fi
    if type -P jq &>/dev/null; then
        token="$(jq -r '.Credentials.SessionToken' <<< "$output")"
    else
        token-"$(awk -F: '/SessionToken/{print $2}' | sed 's/"//')"
    fi
    export AWS_SESSION_TOKEN="$token"
    echo "exported AWS_SESSION_TOKEN"
    echo
    echo "export AWS_SESSION_TOKEN=$token" > ~/.aws/token
    echo "saved to ~/.aws/token for other shells to source via aws_env()"
    echo
    echo "you can now use AWS CLI normally"
}
alias awstoken=aws_token
