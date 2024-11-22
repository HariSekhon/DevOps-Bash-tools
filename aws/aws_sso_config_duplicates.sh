#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-20 18:30:58 +0400 (Wed, 20 Nov 2024)
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
Prints duplicate AWS SSO configs from the given \$AWS_CONFIG_FILE or given file argument

Useful to find and remove / comment out an ~/.aws/config with a mix of hand crafted and automatically generated AWS SSO configs

See also:

    aws_sso_configs.sh - iterates and generates AWS SSO configs for all accounts your currently authenticated user has access to

    aws_sso_configs_save.sh - saves each the above generated configs to ~/.aws/config if they don't already exist by profile name
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_config_file>]"

help_usage "$@"

max_args 1 "$@"

config="${1:-${AWS_CONFIG_FILE:-$HOME/.aws/config}}"

duplicate_account_ids="$(
    grep '^[[:space:]]*sso_account_id' "$config" |
    sed 's/.*=[[:space:]]*//' |
    sort |
    uniq -d
)"

while read -r account_id; do
    if ! is_int "$account_id"; then
        die "ERROR: detected invalid AWS Account ID: $account_id"
    fi
    #grep -10 "^[[:space:]]*sso_account_id[[:space:]]*=[[:space:]]*$account_id" "$config" |
    #sed 's
    #awk "
    #/^\\[/{in_section=0}
    #/sso_account_id[[:space:]]*=[[:space:]]*$account_id/{in_section=1}
    #in_section{print}" "$config"
	awk "
		/^\\[/{section=\$0; in_section=0}
		\$0 ~ /sso_account_id = $account_id/ {in_section=1; print section}
		in_section && \$0 !~ /^\\[/ {print}
	" "$config"
done <<< "$duplicate_account_ids"
