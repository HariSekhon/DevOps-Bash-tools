#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo user={user} org={org} project={project} name={name} repo={repo}
#
#  Author: Hari Sekhon
#  Date: 2021-09-10 14:55:22 +0100 (Fri, 10 Sep 2021)
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
Run a command for each Azure DevOps repo

All arguments become the command template

WARNING: do not run any command reading from standard input, otherwise it will consume the repo names and exit after the first iteration

\$AZURE_DEVOPS_ORGANIZATION / \$AZURE_DEVOPS_USER - the user or organization to iterate the repos on
\$AZURE_DEVOPS_PROJECT - the Azure DevOps project to iterate the repo on

The command template replaces the following for convenience in each iteration:

{organization}, {org} => the organization account being iterated
{username}, {user}    => the user account being iterated
{project}             => the project containing the repo
{name}                => the repo name without the user prefix
{repo}                => the repo name with the user prefix

eg.
    ${0##*/} echo user={user} project={project} name={name} repo={repo}
    ${0##*/} echo org={org}   project={project} name={name} repo={repo}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

user="${AZURE_DEVOPS_USER:-}"
user_or_org="${AZURE_DEVOPS_ORGANIZATION:-$user}"

check_env_defined AZURE_DEVOPS_PROJECT
if is_blank "$user_or_org"; then
    usage "\$AZURE_DEVOPS_ORGANIZATION / \$AZURE_DEVOPS_USER is not defined"
fi

"$srcdir/azure_devops_api.sh" "/$user_or_org/$AZURE_DEVOPS_PROJECT/_apis/git/repositories" |
jq -r '.value[].name' |
sort |
while read -r name; do
    repo="$user_or_org/$name"
    echo "# ============================================================================ #" >&2
    echo "# $repo" >&2
    echo "# ============================================================================ #" >&2
    echo >&2
    cmd=("$@")
    cmd=("${cmd[@]//\{username\}/${user:-}}")
    cmd=("${cmd[@]//\{user\}/${user:-}}")
    cmd=("${cmd[@]//\{organization\}/${AZURE_DEVOPS_ORGANIZATION:-}}")
    cmd=("${cmd[@]//\{org\}/${AZURE_DEVOPS_ORGANIZATION:-}}")
    cmd=("${cmd[@]//\{project\}/${AZURE_DEVOPS_PROJECT:-}}")
    cmd=("${cmd[@]//\{repo\}/$repo}")
    cmd=("${cmd[@]//\{name\}/$name}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
done
