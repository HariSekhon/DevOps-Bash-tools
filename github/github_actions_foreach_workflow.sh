#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: devops-bash-tools echo user={user} repo={repo} name={name} workflow_name={workflow} id={id}
#
#  Author: Hari Sekhon
#  Date: 2021-11-27 11:21:14 +0000 (Sat, 27 Nov 2021)
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
Run a command for each GitHub Actions workflow in the given repo

All arguments after the repo become the command template

WARNING: do not run any command reading from standard input, otherwise it will consume the workflow id/names and exit after the first iteration

\$GITHUB_ORGANIZATION / \$GITHUB_USER - the user or organization to iterate the repos on - if not specified then determines the currently authenticated github user from your \$GITHUB_TOKEN

The command template replaces the following for convenience in each iteration:

{organization}, {org} => the organization account being iterated
{username}, {user}    => the user account being iterated
{repo}                => the repo name with the user prefix
{workflow}, {name}    => the workflow name
{id}, {workflow_id}   => the workflow id

eg.
    ${0##*/} devops-bash-tools echo user={user} repo={repo} name={name} workflow_name={workflow} id={id}
    ${0##*/} devops-bash-tools echo org={org}   repo={repo} name={name} workflow_name={workflow} id={id}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<repo> <command> <args>"

help_usage "$@"

min_args 2 "$@"

repo="$1"
shift || :

"$srcdir/github_actions_workflows.sh" "$repo" |
jq -r '.workflows[] | [.id, .name] | @tsv' |
while read -r id workflow; do
    echo "# ============================================================================ #" >&2
    echo "# $workflow" >&2
    echo "# ============================================================================ #" >&2
    cmd=("$@")
    cmd=("${cmd[@]//\{username\}/${user:-}}")
    cmd=("${cmd[@]//\{user\}/${user:-}}")
    cmd=("${cmd[@]//\{organization\}/${GITHUB_ORGANIZATION:-}}")
    cmd=("${cmd[@]//\{org\}/${GITHUB_ORGANIZATION:-}}")
    cmd=("${cmd[@]//\{repo\}/$repo}")
    cmd=("${cmd[@]//\{name\}/$workflow}")
    cmd=("${cmd[@]//\{workflow\}/$workflow}")
    cmd=("${cmd[@]//\{workflow_id\}/$id}")
    cmd=("${cmd[@]//\{id\}/$id}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
done
