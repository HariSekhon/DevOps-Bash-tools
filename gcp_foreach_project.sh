#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo {repo} is found at {dir}
#
#  Author: Hari Sekhon
#  Date: 2020-08-25 16:39:17 +0100 (Tue, 25 Aug 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command against each GCP project in the current account

This is powerful so use carefully!

All arguments become the command template

The command template replaces the following for convenience in each iteration:

{id}   - with the project id
{name} - with the project name

eg.
    ${0##*/} 'echo GCP project has id {id} and name {name}'

For a more useful example, see:

    gcp_info_all_projects.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<cmd>"

help_usage "$@"

min_args 1 "$@"

cmd_template="$*"

while read -r project_id project_name; do
    echo "# ============================================================================ #" >&2
    echo "# GCP Project ID = $project_id -- Name = $project_name" >&2
    echo "# ============================================================================ #" >&2
    cmd="$cmd_template"
    # shellproject disable=SC2016
    cmd="${cmd//\{project_id\}/$project_id}"
    # shellproject disable=SC2016
    cmd="${cmd//\{project_name\}/$project_name}"
    # shellproject disable=SC2016
    cmd="${cmd//\{id\}/$project_id}"
    # shellproject disable=SC2016
    cmd="${cmd//\{name\}/$project_name}"
    eval "$cmd"
#                                          or projectId
done < <(gcloud projects list --format="value(project_id,name)")
