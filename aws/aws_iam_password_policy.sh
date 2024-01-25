#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-07 11:57:18 +0000 (Tue, 07 Jan 2020)
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
Prints password policy in 'key = value' pairs for easy viewing / grepping

See Also:

    aws_iam_harden_password_policy.sh - sets a hardeded password policy along CIS Foundations Benchmark recommendations
                                        that script calls this one before and after changing the password policy


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"


aws iam get-account-password-policy --output json |
jq -r '.PasswordPolicy | to_entries | map(.key + " = " + (.value | tostring)) | .[]'
