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

    git_origin_commit_count_to_push.sh

    git_origin_line_count_to_push.sh

    git_origin_diff_to_push.sh

    git_origin_files_to_push.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

num_commits="$("$srcdir/git_origin_commit_count_to_push.sh")"

num_lines_changed="$("$srcdir/git_origin_line_count_to_push.sh")"

num_lines_diff="$("$srcdir/git_origin_diff_to_push.sh" | wc -l | sed 's/[[:space:]]*//g')"

files="$("$srcdir/git_origin_files_to_push.sh")"

files_added="$(grep -c '^A' <<< "$files" || :)"

files_modified="$(grep -c '^M' <<< "$files" || :)"

files_deleted="$(grep -c '^D' <<< "$files" || :)"

files_renamed="$(grep -c '^R' <<< "$files" || :)"

files_other="$(grep -c -v '^[AMDR]' <<< "$files" || :)"

files_total="$(grep -c '.' <<< "$files" || :)"

cat <<EOF
Stats for Push to Origin:

    $(git remote -v | awk '/^origin[[:space:]]/{print $2; exit}')

Number of Commits: $num_commits

Number of Lines Changed: $num_lines_changed

Number of Lines Diff: $num_lines_diff

Files Added:    $files_added
Files Modified: $files_modified
Files Deleted:  $files_deleted
Files Renamed:  $files_renamed
Files Other:    $files_other
Files Total:    $files_total

EOF

if [ "$files_total" != "$((files_added + files_modified + files_deleted + files_renamed))" ]; then
    echo
    warn "Total Files != ( Added + Modified + Deleted + Renamed )

Check what the 'Other Files' are
"
fi
