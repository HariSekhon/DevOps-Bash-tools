#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo project id is {id}, name is '{name}'
#
#  Author: Hari Sekhon
#  Date: 2020-08-25 16:39:17 +0100 (Tue, 25 Aug 2020)
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
Run a command against each GCP project in the current account

This is powerful so use carefully!

WARNING: do not run any command reading from standard input, otherwise it will consume the project id/names and exit after the first iteration

Requires GCloud SDK to be installed and configured and 'gcloud' to be in the \$PATH

All arguments become the command template

The following command template tokens are replaced in each iteration:

Project ID:     {id}    {project_id}
Project Name:   {name}  {project_name}


eg.
    ${0##*/} 'echo GCP project has id {id} and name {name}'


For a more useful example, see:

    gcp_info_all_projects.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

# don't need to capture and replace project in config as done in environment variable now as it's much safer as it's limited to only this script and its child processes
#current_project="$(gcloud config list --format="value(core.project)")"
#if [ -n "$current_project" ]; then
#    # want interpolation now not at exit
#    # shellcheck disable=SC2064
#    trap "gcloud config set project '$current_project'" EXIT
#else
#    trap "gcloud config unset project" EXIT
#fi

projects="$(gcloud projects list --format="value(project_id,name)")"

total_projects="$(grep -c . <<< "$projects")"

i=0

while read -r project_id project_name; do
    (( i += 1 ))
    echo "# ============================================================================ #" >&2
    echo "# ($i/$total_projects) GCP Project ID = $project_id -- Name = $project_name" >&2
    echo "# ============================================================================ #" >&2
    # XXX: this would cause a concurrency race condition bug between other scripts and sessions that could be dangerous
    #gcloud config set project "$project_id"
    export CLOUDSDK_CORE_PROJECT="$project_id"
    cmd=("$@")
    cmd=("${cmd[@]//\{project_id\}/$project_id}")
    cmd=("${cmd[@]//\{project_name\}/$project_name}")
    cmd=("${cmd[@]//\{project\}/$project_id}")
    cmd=("${cmd[@]//\{id\}/$project_id}")
    cmd=("${cmd[@]//\{name\}/$project_name}")
    # need eval'ing to able to inline quoted script
    # shellcheck disable=SC2294
    eval "${cmd[@]}"
    echo >&2
    echo >&2
done <<< "$projects"
