#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2012-09-01 13:01:11 +0100
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                A W S  -  A m a z o n   W e b   S e r v i c e s
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
type add_PATH &>/dev/null || . "$bash_tools/.bash.d/paths.sh"
# shellcheck disable=SC1090,SC1091
#type autocomplete &>/dev/null || . "$bash_tools/.bash.d/functions.sh"

# ==================
# AWS CLI completion

aws_completer="$(type -P aws_completer 2>/dev/null)"

if [ -n "$aws_completer" ]; then
    complete -C "$aws_completer" aws
fi

#autocomplete eksctl

# =====================
# Elastic Beanstalk CLI (easier to use than AWS CLI)

if [ -d ~/.ebcli-virtual-env/executables/ ]; then
    add_PATH ~/.ebcli-virtual-env/executables/
fi

# ============================================================================ #
#                   A l i a s e s   a n d   F u n c t i o n s
# ============================================================================ #

alias awsl='aws sso login'

#alias s3='s3cmd'
alias s3='aws s3'
alias dockerecr='aws ecr get-login-password | docker login -u AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com'

alias awscon='aws_consoler -o'
alias awsc='awscon'

alias aws_whoami="aws sts get-caller-identity"
alias awhoami=aws_whoami

# loads creds from a CLI cache file (eg. for AWS SSO) into environment variables
# better done via direnv
awscreds(){
    # should be something like ~/.aws/cli/cached/[hash].json
    local cred_cache_file="$1"
    AWS_ACCESS_KEY_ID="$(jq -r .Credentials.AccessKeyId < "$cred_cache_file")"
    AWS_SECRET_ACCESS_KEY="$(jq -r .Credentials.SecretAccessKey < "$cred_cache_file")"
    AWS_SESSION_TOKEN="$(jq -r .Credentials.SessionToken < "$cred_cache_file")"
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    export AWS_SESSION_TOKEN
}

# ==================
# AWLess completion

alias awl=awless
alias assh="awless ssh"

#autocomplete awless
# make completion work with awl alias above
#if ! [ -f ~/.bash.autocomplete.d/awl.sh ]; then
#    sed 's/awless/awl/g' ~/.bash.autocomplete.d/awless.sh > ~/.bash.autocomplete.d/awl.sh
#fi
#autocomplete awl

# ==================

# JAVA_HOME needs to be set to use EC2 api tools
#[ -x /usr/bin/java ] && export JAVA_HOME=/usr  # errors but still works

# Shouldn't be needed any more, all these sorts of tools were unified on awscli
#
# link_latest '/usr/local/ec2-api-tools-*'
#if [ -d /usr/local/ec2-api-tools/bin ]; then
#    export EC2_HOME=/usr/local/ec2-api-tools   # this should be a link to the unzipped ec2-api-tools-1.6.1.4/
#    add_PATH "$EC2_HOME/bin"
#fi

# ============================================================================ #

# Old: new direnv now
#
# ec2dre - ec2-describe-regions - list regions you have access to and put them here
# TODO: pull a more recent list and have aliases/functions auto-generated from that to export
#aws_eu(){
#    export EC2_URL=ec2.eu-west-1.amazonaws.com
#}
#aws_useast(){
#    export EC2_URL=ec2.us-east-1.amazonaws.com
#}
#aws_eu

# ============================================================================ #

# https://github.com/remind101/assume-role
assume-role(){
    #eval "$(command assume-role "$@")"
    local output
    output="$(command assume-role "$@")"
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        eval "$output"
    fi
}

# ============================================================================ #

aws_get_cred_path(){
    # unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
    [ -n "${HOME:-}" ] || HOME=~
    local aws_credentials="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
    local aws_config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
    local boto="${BOTO_CONFIG:-$HOME/.boto}"
    local credentials_file
    if [ -f "$aws_credentials" ]; then
        credentials_file="$aws_credentials"
    # older boto creds
    elif [ -f "$boto" ]; then
        credentials_file="$boto"
    elif [ -f "$aws_config" ]; then
        credentials_file="$aws_config"
    else
        echo "no credentials found - didn't find $aws_credentials or $boto or $aws_config" 2>/dev/null
        return 1
    fi
    echo "$credentials_file"
}

# this rarely changes so just set it once as initialization instead of passing lots of params
# or re-executing aws_get_cred_path() multiple times in different functions
aws_credentials_file="$(aws_get_cred_path)"

aws_clean_env(){
    echo "clearing AWS_* environment variables"
    while read -r envvar; do
        unset "$envvar"
    done < <(env | sed -n '/^AWS_/ s/=.*// p')
}

# easily set a profile env var
#aws_profile(){
#    # false positive
#    # shellcheck disable=SC2317
#    export AWS_PROFILE="$*"
#}

alias awsprofile=aws_profile.sh
alias awsp=aws_profile.sh

aws_get_profile_data(){
    local profile="$1"
    local filename="${2:-$aws_credentials_file}"
    sed -n "/[[:space:]]*\\[\\(profile[[:space:]]*\\)*$profile\\]/,/^[[:space:]]*\\[/p" "$filename"
}

# Storing creds in one place in Boto creds file, pull them straight from there
# if only using new creds, might want to just export AWS_PROFILE instead using aws_profile which provides validation
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
        # shellcheck disable=SC1090,SC1091
        source "$aws_token"
    fi
}
alias awsenv=aws_env

aws_envs(){
    awk '/^[[:space:]]*\[.+\]/{print $1}' < "$aws_credentials_file" |
    sed 's/\[//;s/\]//' |
    while read -r profile; do
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
    set -x
    output="$(aws sts get-session-token --serial-number "$AWS_MFA_ARN" --duration-seconds "${AWS_STS_DURATION_SECS:-129600}" --token-code "$@")"
    result=$?
    set +x
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
