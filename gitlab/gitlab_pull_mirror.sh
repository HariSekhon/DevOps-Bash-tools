#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-01 13:54:41 +0100 (Tue, 01 Sep 2020)
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Trigger a GitLab mirror pull of a given project's repo

Project can be specified as a Project ID or a Project name

If no repo is given, tries to determine from the current git checkout

Outputs '200' indicating OK if successful
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project> [<curl_options>]"

help_usage "$@"

#min_args 1 "$@"

if [ -n "${GITLAB_USER:-}" ]; then
    user="$GITLAB_USER"
else
    # get currently authenticated user
    user="$("$srcdir/gitlab_api.sh" /user | jq -r .username)"
fi

if [ $# -gt 0 ]; then
    project="$1"
    shift || :
else
    project="$(git_repo)"
fi

if [[ "$project" =~ / ]]; then
    project="${project//\//%2F}"
elif [[ "$project" =~ ^[[:digit:]]$ ]]; then
    :
else
    project="$user%2F$project"
fi

"$srcdir/gitlab_api.sh" "/projects/$project/mirror/pull" -X POST "$@"
echo
