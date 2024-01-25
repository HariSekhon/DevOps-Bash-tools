#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo owner={owner} repo={repo}
#
#  Author: Hari Sekhon
#  Date: 2020-08-30 10:08:07 +0100 (Sun, 30 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
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
Run a command for each original non-fork GitHub repo

All arguments become the command template

WARNING: do not run any command reading from standard input, otherwise it will consume the repo names and exit after the first iteration

\$GITHUB_ORGANIZATION / \$GITHUB_USER - the user or organization to iterate the repos on - if not specified then determines the currently authenticated github user from your \$GITHUB_TOKEN

The command template replaces the following for convenience in each iteration:

{owner}               => the user or organization that owns the repo eg. HariSekhon or MyOrg, whichever owns the repo
{repo}                => the repo name without the owner prefix eg. DevOps-Bash-tools

eg.
    ${0##*/} echo owner={owner}  name={name} repo={repo}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

owner="${GITHUB_ORGANIZATION:-${GITHUB_USER:-$(get_github_user)}}"

get_github_repos "$owner" "${GITHUB_ORGANIZATION:-}" |
while read -r repo; do
    owner_repo="$owner/$repo"
    echo "# ============================================================================ #" >&2
    echo "# $owner_repo" >&2
    echo "# ============================================================================ #" >&2
    echo >&2
    cmd=("$@")
    cmd=("${cmd[@]//\{owner\}/$owner}")
    cmd=("${cmd[@]//\{repo\}/$repo}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
done
