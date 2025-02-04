#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-04 22:01:06 +0700 (Tue, 04 Feb 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
For a list of AWS Account IDs in stdin or files (containing one account id per line),
finds those missing from AWS config

You can override the config file location by setting environment variable AWS_CONFIG_FILE


$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<files>]"

help_usage "$@"

#min_args 0 "$@"

HOME="${HOME:-$(cd && pwd)}"

aws_config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"

# force functions to log with timestamps
export VERBOSE=1

account_ids="$(
    sed '
        s/#.*//;
        s/^[[:space:]]*//;
        s/[[:space:]]*$//;
        /^[[:space:]]*$/d
    ' "$@"
)"

timestamp "AWS Account IDs not found in: $aws_config"
echo >&2
while read -r aws_account_id; do
    if ! is_aws_account_id "$aws_account_id"; then
        warn "Invalid AWS Account ID: $aws_account_id"
    fi
    if ! grep -Fq "$aws_account_id" "$aws_config"; then
        echo "$aws_account_id"
    fi
done <<< "$account_ids"
