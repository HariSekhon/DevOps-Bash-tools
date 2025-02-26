#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo project id is {id}, number is '{number}', name is '{name}'
#
#  Author: Hari Sekhon
#  Date: 2025-02-27 00:58:45 +0700 (Thu, 27 Feb 2025)
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
Run a command against each Google Firebase project in the current account

This is powerful so use carefully!

WARNING: do not run any command reading from standard input, otherwise it will consume the project id/names and exit after the first iteration

Requires Firebase CLI to be installed and configured be in the \$PATH

All arguments become the command template

The following command template tokens are replaced in each iteration:

Project ID:     {id}     {project_id}
Project Number: {number} {project_number}
Project Name:   {name}   {project_name}


eg.
    ${0##*/} 'echo Firebase project has id {id}, number {number} and name {name}'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"


projects="$(
    firebase projects:list --json |
    jq -r '
        .result[] |
        [.projectId, .projectNumber, .displayName] |
        @tsv
    '
)"

total_projects="$(grep -c . <<< "$projects")"

i=0

while read -r project_id project_number project_name; do
    (( i += 1 ))
    echo "# ======================================================================================================== #" >&2
    echo "# ($i/$total_projects) Firebase Project ID = $project_id -- Number = $project_number -- Name = $project_name" >&2
    echo "# ======================================================================================================== #" >&2
    cmd=("$@")
    cmd=("${cmd[@]//\{project_id\}/$project_id}")
    cmd=("${cmd[@]//\{project_name\}/$project_name}")
    cmd=("${cmd[@]//\{project_number\}/$project_number}")
    cmd=("${cmd[@]//\{project\}/$project_id}")
    cmd=("${cmd[@]//\{id\}/$project_id}")
    cmd=("${cmd[@]//\{name\}/$project_name}")
    cmd=("${cmd[@]//\{number\}/$project_number}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
    echo >&2
done <<< "$projects"
