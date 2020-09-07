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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command for each original non-fork GitHub repo

All arguments become the command template

The command template replaces the following for convenience in each iteration:

{username}, {user}    => your authenticated user
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

cmd_template="$*"

user="$(get_github_user)"

while read -r name; do
    repo="$user/$name"
    echo "# ============================================================================ #" >&2
    echo "# $repo" >&2
    echo "# ============================================================================ #" >&2
    cmd="$cmd_template"
    cmd="${cmd//\{username\}/$user}"
    cmd="${cmd//\{user\}/$user}"
    cmd="${cmd//\{repo\}/$repo}"
    cmd="${cmd//\{name\}/$name}"
    eval "$cmd"
done < <(get_github_repos "$user")
