#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  run: GIT_USERNAME=hari-s GIT_PASSWORD=testpass git_askpass.sh get
#
#  Author: Hari Sekhon
#  Date: 2022-08-24 15:35:06 +0100 (Wed, 24 Aug 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://git-scm.com/docs/gitcredentials

# https://git-scm.com/docs/git-credential

set -euo pipefail
# doesn't seem to pass through DEBUG environment variable when called via 'git credential fill' - will need to set -x explicitly
[ -n "${DEBUG:-}" ] && set -x
#set -x

usage(){
    cat <<EOF
GIT_ASKPASS credential script to allow loading credentials from environment variables to Git dynamically

The \$GIT_ASKPASS environment variable should be set to the location of this script to have Git call it automatically

This program is designed to be called by the 'git' command in the form of:

    git credential fill

Full example command:

    echo url=https://github.com | GIT_ASKPASS=$0 git credential fill

which calls this script like so:

    ${0##*/} get


Environment variables used if available, in precedence order from left to right:

    username = \$GIT_USERNAME, \$GIT_USER
    password = \$GIT_TOKEN, \$GIT_PASSWORD


usage: ${0##*/} get
EOF
    exit 3
}

if [ $# -ne 1 ] || [[ $* =~ - ]]; then
    usage
fi

username_variables="
GIT_USERNAME
GIT_USER
"

password_variables="
GIT_TOKEN
GIT_PASSWORD
"

output_variable(){
    local key="$1"
    local variables="$2"
    for var in $variables; do
        if [ -n "${!var:-}" ]; then
            echo "$key=${!var}"
            break
        fi
    done
}

if [ "$1" = get ]; then
    output_variable username "$username_variables"
    output_variable password "$password_variables"

# have observed Git version 2.27.0 in ArgoCD calling the GIT_ASKPASS program twice with these 2 first arguments:
#
#   'Username for '\''https://github.com'\''
#
# and
#
#   'Password for '\''https://github.com'\''
#
# and then taking the entire first line returned as the value
elif [[ "$*" =~ Username ]]; then
    output_variable username "$username_variables" | sed 's/^username=//'
elif [[ "$*" =~ Password ]]; then
    output_variable password "$password_variables" | sed 's/^password=//'
fi
