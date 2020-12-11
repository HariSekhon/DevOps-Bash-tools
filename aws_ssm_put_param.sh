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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Reads a value from the command line and saves it to AWS Systems Manager Parameter Store

usage: aws_ssm_put_param.sh [<key>] [<value>]

first argument is used as key - if not given prompts for it
second argument is used as value - if not given prompts for it (recommended for secrets)


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"


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
