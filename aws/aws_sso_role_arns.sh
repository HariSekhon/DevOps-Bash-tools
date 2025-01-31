#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-03 09:47:12 +0700 (Tue, 03 Dec 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Prints all AWS SSO ARNs in IAM policy usable format


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
#usage_args="[<aws_sso_args>]"
usage_args=""

help_usage "$@"

#num_args 0 "$@"

#timestamp "Checking if AWS SSO is already logged in"
#if is_aws_sso_logged_in; then
#    timestamp "Already authenticated to AWS SSO, skipping login for speed"
#else
#    timestamp "Not currently authenticated to AWS SSO, launching login:"
#    echo >&2
#    aws sso login "$@"
#    echo >&2
#fi

aws iam list-roles --query 'Roles[*].Arn' --output text |
tr '[:space:]' '\n' |
grep 'aws-reserved/sso.amazonaws.com' |
# strip the middle bit which isn't in the IAM policy format
sed ' s|aws-reserved/sso.amazonaws.com/[^/]*/||'
