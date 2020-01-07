#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-06 11:40:22 +0000 (Mon, 06 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Reads a value from the command line and saves it to AWS Systems Manager Parameter Store
#
# usage: aws_ssm_put_param.sh [<key>] [<value>]
#
# first argument is used as key - if not given prompts for it
# second argument is used as value - if not given prompts for it (recommended for secrets)
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

key="${1:-}"
value="${2:-}"

if [ -z "$key" ]; then
    read -r -p "Enter key: " key
fi

if [ -z "$value" ]; then
    # doesn't echo, let's print a star per character instead as it's nicer feedback
    #read -s -p "Enter value: " value

    value=""
    prompt="Enter value: "
    while IFS= read -p "$prompt" -r -s -n 1 char; do
        if [[ "$char" == $'\0' ]]; then
            break
        fi
        prompt='*'
        value="${value}${char}"
    done
    echo
fi

aws ssm put-parameter --name "$key" --value "$value" --type SecureString --overwrite
