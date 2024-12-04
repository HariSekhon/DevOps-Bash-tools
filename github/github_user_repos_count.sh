#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: harisekhon
#
#  Author: Hari Sekhon
#  Date: 2024-08-21 03:35:51 +0200 (Wed, 21 Aug 2024)
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

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the total number of original source public GitHub repos for a given username

Output format:

<number_of_original_public_repos>


Requires GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<username> <public_only_flag>]"

help_usage "$@"

max_args 2 "$@"

username="${1:-}"

is_public="${2:-}"

select_private="select(.)"
if [ -n "${is_public:-}" ]; then
    select_private="select(.isPrivate | not)"
fi

gh repo list \
    ${username:+"$username"} \
    --limit 99999 \
    --json isFork,isPrivate \
    --jq "
        [
            .[] |
            select(.isFork | not) |
            $select_private
        ] |
        length
    "
