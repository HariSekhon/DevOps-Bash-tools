#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-09 18:39:14 +0000 (Wed, 09 Feb 2022)
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
Triggers all workflows in the current or given GitHub repo

Requires GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<user>/<repo> <gh_options>]"

check_env_defined "GITHUB_TOKEN"

help_usage "$@"

max_args 1 "$@"

owner_repo='{owner}/{repo}'
args=()
if [ $# -gt 0 ]; then
    repo="$1"
    shift || :
    owner_repo="$repo"
    args+=(-R "$repo")
fi

gh api "/repos/$owner_repo/actions/workflows" -q '.workflows[].name' |
while read -r workflow_name; do
    timestamp "Triggering workflow: $workflow_name"
    gh workflow run ${args:+"${args[@]}"} "$workflow_name" "$@"
done
