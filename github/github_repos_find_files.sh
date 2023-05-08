#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: Dockerfile
#
#  Author: Hari Sekhon
#  Date: 2022-10-11 09:26:55 +0100 (Tue, 11 Oct 2022)
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
Finds files matching the given name across all repos in the current organization or user using the GitHub API & CLI

Output Format:

<owner>/<repo>    <file_path>
<owner>/<repo2>   <file_path2>


Requires GitHub CLI to be installed and configured, as well as the adjacent github_api.sh script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename_regex>"

help_usage "$@"

min_args 1 "$@"

filename="$1"

owner="${GITHUB_ORGANIZATION:-${GITHUB_USER:-$(get_github_user)}}"

get_github_repos "$owner" "${GITHUB_ORGANIZATION:-}" |
while read -r repo; do
    gh api "/repos/$owner/$repo/git/trees/HEAD?recursive=1" |
    jq -r ".tree[]?.path | select(. | test(\"$filename\") )" |
    sed $"s|^|$owner/$repo\\t|"
done
