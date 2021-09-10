#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo user={user} name={name} repo={repo}
#
#  Author: Hari Sekhon
#  Date: 2020-08-30 10:08:07 +0100 (Sun, 30 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command for each original non-fork GitHub repo

All arguments become the command template

\$GITHUB_ORGANIZATION / \$GITHUB_USER - the user or organization to iterate the repos on - if not specified then determines the currently authenticated github user from your \$GITHUB_TOKEN

The command template replaces the following for convenience in each iteration:

{organization}, {org} => the organization account being iterated
{username}, {user}    => the user account being iterated
{name}                => the repo name without the user prefix
{repo}                => the repo name with the user prefix

eg.
    ${0##*/} echo user={user} name={name} repo={repo}
    ${0##*/} echo org={org}   name={name} repo={repo}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

cmd_template="$*"

user="${GITHUB_USER:-$(get_github_user)}"
user_or_org="${GITHUB_ORGANIZATION:-$user}"

get_github_repos "$user_or_org" "${GITHUB_ORGANIZATION:-}" |
while read -r name; do
    repo="$user_or_org/$name"
    echo "# ============================================================================ #" >&2
    echo "# $repo" >&2
    echo "# ============================================================================ #" >&2
    cmd="$cmd_template"
    cmd="${cmd//\{username\}/${user:-}}"
    cmd="${cmd//\{user\}/${user:-}}"
    cmd="${cmd//\{organization\}/${GITHUB_ORGANIZATION:-}}"
    cmd="${cmd//\{org\}/${GITHUB_ORGANIZATION:-}}"
    cmd="${cmd//\{repo\}/$repo}"
    cmd="${cmd//\{name\}/$name}"
    eval "$cmd"
done
