#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-11-24 12:40:18 +0000 (Wed, 24 Nov 2021)
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
Retrieves a secret value from a given AWS Secrets Manager secret name

First argument is used as secret name
Remaining args are passed directly to 'aws secretsmanager'

Will check for and output Secret String or Secret Binary

Example:

    ${0##*/} my-secret


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<name>"

help_usage "$@"

min_args 1 "$@"

name="$1"
shift || :

aws secretsmanager get-secret-value --secret-id "$name" "$@" |
jq -r 'if .SecretString then .SecretString else .SecretBinary end'
