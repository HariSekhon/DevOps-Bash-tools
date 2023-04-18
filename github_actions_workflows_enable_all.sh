#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-11-28 11:11:51 +0000 (Sun, 28 Nov 2021)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Enables all GitHub Actions workflows via the API

Use to re-enable all your workflows as GitHub has started disabling workflows in repos after 6 months without a commit
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<repo>]"

help_usage "$@"

max_args 1 "$@"

repo="${1:-}"

if [ -z "$repo" ]; then
    repo="$(get_github_repo)"
fi

USER="${GITHUB_ORGANIZATION:-${GITHUB_USER:-$(get_github_user)}}"

if ! [[ $repo =~ / ]]; then
    repo="$USER/$repo"
fi

timestamp "Enabling all github actions workflows in repo '$repo'"
"$srcdir/github_actions_foreach_workflow.sh" "$repo" "$srcdir/github_actions_workflow_enable.sh" "$repo" "{id}"
