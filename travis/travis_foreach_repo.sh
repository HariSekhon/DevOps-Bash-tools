#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: bash -c 'echo user={user} name={name} repo={repo}'
#
#  Author: Hari Sekhon
#  Date: 2020-09-30 23:53:57 +0100 (Wed, 30 Sep 2020)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command for each Travis CI repo

All arguments become the command template

WARNING: do not run any command reading from standard input, otherwise it will consume the repo names and exit after the first iteration

The command template replaces the following for convenience in each iteration:

{username}, {user}    => your authenticated user / organization
{name}                => the repo name without the user prefix
{repo}                => the repo name with the user prefix

eg.
    ${0##*/} echo user={user} name={name} repo={repo}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

"$srcdir/travis_repos.sh" |
while read -r repo; do
    user="${repo%%/*}"
    name="${repo##*/}"
    if [ -z "${NO_HEADING:-}" ]; then
        echo "# ============================================================================ #" >&2
        echo "# $repo" >&2
        echo "# ============================================================================ #" >&2
    fi
    cmd=("$@")
    cmd=("${cmd[@]//\{username\}/$user}")
    cmd=("${cmd[@]//\{user\}/$user}")
    cmd=("${cmd[@]//\{repo\}/$repo}")
    cmd=("${cmd[@]//\{name\}/$name}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    if [ -z "${NO_HEADING:-}" ]; then
        echo >&2
    fi
done
