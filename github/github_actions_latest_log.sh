#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-03-21 23:16:42 +0800 (Fri, 21 Mar 2025)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Outputs the text log of the latest GitHub Actions workflow run to the terminal

Useful when the logs are too big for the UI and you have to open it in another tab which is very slow in browser

Uses adjacent script:

    github_actions_log.sh

Requires GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner>/<repo>]"

help_usage "$@"

max_args 2 "$@"

owner_repo="${1:-}"

if [ -n "$owner_repo" ]; then
    is_github_owner_repo "$owner_repo" || die "Invalid GitHub owner/repo given: $owner_repo"
else
    owner_repo="$(github_owner_repo)"
fi

"$srcdir/github_actions_log.sh" "$owner_repo" 1
