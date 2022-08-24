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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    cat <<EOF
GIT_ASKPASS credential script to allow loading credentials from environment variables to Git dynamically

This program is designed to be called by the 'git' command in the form of:

    git credential get


Environment variables that are returned:

    GIT_USERNAME / GIT_USER
    GIT_TOKEN / GIT_PASSWORD
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
fi
