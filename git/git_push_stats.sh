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
Shows the Git push stats to the remote origin for the current branch - number of commits and lines of diff

Utilizes adjacent scripts:

    git_origin_log_to_head.sh

    git_origin_diff_to_head.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

num_commits="$("$srcdir/git_origin_commits_to_push.sh")"

num_lines_diff="$("$srcdir/git_origin_diff_to_push.sh" | wc -l | sed 's/[[:space:]]*//g')"

# delete the last line of diff only if it's blank,
# so that when there is nothing to push we get 0 instead of 1 line as the result
num_lines_changed="$("$srcdir/git_origin_lines_changed_to_push.sh")"

cat <<EOF
Stats for Push to Origin

Number of Commits: $num_commits

Number of Lines Changed: $num_lines_changed

Number of Lines Diff: $num_lines_diff

EOF
