#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 11:15:51 +0100 (Sun, 16 Aug 2020)
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

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=lib/git.sh
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists a GitHub repo's stars and forks using the GitHub API

If no repo is given, infers from local repo's git remotes

Output format:

<repo>  <stars>  <forks>  <watchers>
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<repo> [<curl_options>]"

help_usage "$@"

#min_args 1 "$@"

repo="${1:-}"

if [ -z "$repo" ]; then
    repo="$(git_repo)"
fi

"$srcdir/github_api.sh" "/repos/$repo" |
jq -r '[.name, .stargazers_count, .forks, .watchers] | @tsv'
