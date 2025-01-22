#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-23 03:23:55 +0700 (Thu, 23 Jan 2025)
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Shows the Git diff of lines in local branch that would be pushed to remote origin

You can give git diff options

Example:

    ${0##*/} --color=always | less -FR
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<git_diff_options>"

help_usage "$@"

#min_args 1 "$@"

log "Determining current branch"
current_branch="$(current_branch)"
log "Current branch: $current_branch"

log "Checking we have an origin"
git remote get-url origin >/dev/null

#git diff "origin/$current_branch.."

# these next two work even if you haven't pushed this branch yet
#git diff "$@" "FETCH_HEAD..HEAD"
git diff "$@" "origin.."
