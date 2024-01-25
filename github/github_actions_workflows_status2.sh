#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-03 14:45:29 +0000 (Thu, 03 Feb 2022)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists the last completed status of all GitHub Actions workflows

Requires GitHub CLI to be installed and configured with a \$GITHUB_TOKEN
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

seen=()

gh run list -L 200 --json  name,status,conclusion \
                   -q '.[] |
                       select(.status == "completed") |
                       [.conclusion, .name] | @tsv' |
while read -r conclusion name; do
    if ! printf '%s\n' "${seen[@]}" | grep -Fixq "$name"; then
        printf '%-10s\t%s\n' "$conclusion" "$name"
        seen+=("$name")
    fi
done
