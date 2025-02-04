#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-11-20 20:47:15 +0400 (Wed, 20 Nov 2024)
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
Reads AWS profile config blocks from stdin and appends them to the ~/.aws/config file if the profile section is not found

You can override the config file location by setting environment variable AWS_CONFIG_FILE

Uses adjacent script:

    ../data/ini_config_add_if_missing.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<aws_config_file>]"

help_usage "$@"

max_args 1 "$@"

aws_config_file="${1:-${AWS_CONFIG_FILE:-$HOME/.aws/config}}"

# designed to support AWS config sections which require a profile prefix
export SECTION_PREFIX="profile"

"$srcdir/../data/ini_config_add_if_missing.sh" "$aws_config_file"
