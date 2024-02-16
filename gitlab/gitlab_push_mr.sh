#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-16 21:58:25 +0000 (Fri, 16 Feb 2024)
#
#  https://gitlab.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/gitlab.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Pushes the current branch to GitLab origin, sets upstream branch, then raises a Pull Request to the given or default branch

If \$GITLAB_MERGE_PULL_REQUEST=true then will automatically merge the pull request as well

"
#If \$GITLAB_MERGE_PULL_REQUEST_AS_ADMIN=true then will merge as admin to bypass branch merge protection

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<target_base_branch> <title> <description>]"

help_usage "$@"

#min_args 1 "$@"
max_args 3 "$@"

check_gitlab_origin

base_branch="${1:-$(default_branch)}"
title="${2:-}"
description="${3:-}"

git push --set-upstream origin "$(current_branch)"

echo

current_branch="$(current_branch)"

# check for existing MR first
existing_mr="$(glab mr list -s "$current_branch" -t "$base_branch" | grep -F "$current_branch" || :)"
if [ -n "$existing_mr" ]; then
    timestamp "Merge Request already exists, skipping creation"
    echo
    echo "$existing_mr"
    id="${existing_mr%%[[:space:]]*}"
    id="${id#!}"
    url="$(glab mr view "$id" | grep '^url:[[:space:]]' | sed 's/^url:[[:space:]]*//')"
else
    output="$(glab mr create ${title:+--title "$title"} ${description:+--description "$description"} "${description:---fill}" --yes --source-branch "$current_branch" --target-branch "$base_branch" --remove-source-branch)"
    echo "$output"
    echo
    if [ -z "$output" ]; then
        die "Pull request not created"
    fi
    url="$(parse_pull_request_url "$output")"
fi
echo

if [ "${GITLAB_MERGE_PULL_REQUEST:-}" = true ]; then
    #args=""
    #if [ "${GITLAB_MERGE_PULL_REQUEST_AS_ADMIN:-}" = true ]; then
    #    args="--admin"
    #fi
    timestamp "Merging Pull Request:  $url"
    id="${url##*/}"
    glab mr merge "$id" --yes
fi

if is_mac; then
    echo "Opening Pull Request"
    open "$url"
elif [ -n "${BROWSER:-}" ]; then
    echo "Opening Pull Request using \$BROWSER"
    "$BROWSER" "$url"
else
    echo "\$BROWSER environment variable not set and not on Mac to use default browser, not opening browser"
fi
