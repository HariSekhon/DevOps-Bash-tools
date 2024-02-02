#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: gitlab-org/cli
#
#  Author: Hari Sekhon
#  Date: 2022-01-10 18:33:13 +0000 (Mon, 10 Jan 2022)
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
Returns the latest release name/version for a given 'owner/repo' project via the GitLab API

If a project repo has no releases, gets a 404 error

Requires curl and jq to be installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner>/<repo>"

help_usage "$@"

check_bin curl
check_bin jq

min_args 1 "$@"

owner_repo="$1"

if ! is_github_owner_repo "$owner_repo"; then
    die "Invalid owner/repo argument given: $owner_repo"
fi

owner_repo="${owner_repo//\//%2F}"

if [ -n "${GITHUB_TOKEN:-}" ]; then
    CURL_OPTS="-ssL --fail" "$srcdir/gitlab_api.sh" "/projects/$owner_repo/releases/permalink/latest"
else
    curl -sSL --fail "https://api.github.com/projects/$owner_repo/permalink/releases/latest"
fi |
jq_debug_pipe_dump |
jq -e -r .tag_name ||
die "Failed to determine latest release"
