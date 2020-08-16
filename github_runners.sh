#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-12 16:21:52 +0000 (Wed, 12 Feb 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/git.sh
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Script to get GitHub Actions Runners for the local git repo via the GitHub API

If no repo arg is given and is inside a git repo then takes determines the repo from the first git remote listed

\$REPO environment variable may be used with first args taking precedence
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<repo>"

help_usage "$@"

repo="${1:-${REPO:-}}"

if [ -z "$repo" ]; then
    repo="$(git_repo)"
fi

if [ -z "$repo" ]; then
    usage "repo not specified and couldn't determine from git remote command"
fi

any_opt_usage "$@"

USER="${GITHUB_USER:-${USERNAME:-${USER}}}"
PASSWORD="${GITHUB_PASSWORD:-${GITHUB_TOKEN:-${PASSWORD:-}}}"

if ! [[ $repo =~ / ]]; then
    repo="$USER/$repo"
fi

"$srcdir/github_api.sh" "/repos/$repo/actions/runners" |
jq -r '.runners[] | [.id, .status, .os, .name] | @tsv' |
column -t
