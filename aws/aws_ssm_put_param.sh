#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-06 11:40:22 +0000 (Mon, 06 Jan 2020)
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
Reads a value from the command line and saves it to AWS Systems Manager Parameter Store

first argument is used as key - if not given prompts for it
second argument is used as value - if not given prompts for it (recommended for secrets)


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<key> [<value>]"

help_usage "$@"

min_args 1 "$@"

key="$1"
secret="${2:-}"

if [ -z "$secret" ]; then
    read_secret value
fi

aws ssm put-parameter --name "$key" --value "$secret" --type SecureString --overwrite
