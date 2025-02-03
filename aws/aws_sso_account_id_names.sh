#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-03 17:38:53 +0700 (Mon, 03 Feb 2025)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Parses your \$AWS_CONFIG_FILE ini config for AWS SSO to output AWS Account IDs and Profile Names

Output:

<account_id>  <profile_name>


This is one of the most rudimentary scripts in this repo, so it could break if you have a non-uniform
AWS config file - you must check the results yourself. If you've generated your AWS SSO config using the
adjacent scripts then it should be fine:

    aws_sso_configs.sh

    aws_sso_configs_save.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<[aws_config_file>]"

help_usage "$@"

max_args 1 "$@"

aws_config="${1:-${AWS_CONFIG_FILE:-$(cd && pwd)/.aws/config}}"

#grep -e '^\[profile' \
#     -e '^[[:space:]]*sso_account_id' \
#    "$aws_config" |
#sed '
#    N;
#    s/^[[:space:]]*#.*//;
#    /^[[:space:]]*$/d;
#    s/\[profile //;
#    s/\n/ /;
#    s/^\([^ ]*\) \(.*\)$/\2  # \1/
#    s/^[[:space:]]*sso_account_id[[:space:]]*=[[:space:]]*//;
#    s/\][[:space:]]*$//;
#'

awk '
  /^\[profile / {
    profile = gensub(/^\[profile (.*)]$/, "\\1", 1)
  }
  /^[[:space:]]*sso_account_id/ {
    gsub(/^[[:space:]]*sso_account_id = /, "", $0)
    print $0, profile
  }
' "$aws_config" |
column -t
