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
Lists duplicate AWS SSO config profile names that are using the same sso_account_id
from the given file or \$AWS_CONFIG_FILE

Useful to find and remove / comment out an ~/.aws/config with a mix of hand crafted
and automatically generated AWS SSO configs

See also:

    aws_sso_config_duplicate_sections.sh

    aws_sso_configs.sh - iterates and generates AWS SSO configs for all accounts your currently authenticated user has access to

    aws_sso_configs_save.sh - saves each the above generated configs to ~/.aws/config if they don't already exist by profile name
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_config_file>]"

help_usage "$@"

max_args 1 "$@"

config="${1:-${AWS_CONFIG_FILE:-$HOME/.aws/config}}"

if ! [ -f "$config" ]; then
    die "ERROR: file does not exist: $config"
fi

duplicate_account_ids="$(
    grep '^[[:space:]]*sso_account_id[[:space:]]*=' "$config" |
    sed 's/.*=[[:space:]]*//' |
    sort |
    uniq -d |
    sed '/^[[:space:]]*$/d'
)"

while read -r account_id; do
    if is_blank "$account_id"; then
        continue
    fi
    if ! is_int "$account_id"; then
        die "ERROR: detected invalid AWS Account ID: $account_id"
    fi
    while read -r line; do
        if is_blank "$line"; then
            continue
        elif [[ "$line" =~ ^[[:space:]]*\[.+\] ]]; then
            section="$line"
        elif [[ "$line" =~ ^[[:space:]]*sso_account_id[[:space:]]*=[[:space:]]*${account_id}[[:space:]]*$ ]]; then
            echo "$section"
        fi
    done < "$config"
done <<< "$duplicate_account_ids" |
sed '
    s/^[^[]*\[//;
    s/^[[:space:]]*profile[[:space:]]*//;
    s/\][^]]*$//;
' |
sort -fu
