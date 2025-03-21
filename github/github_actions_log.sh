#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-03-21 23:16:42 +0800 (Fri, 21 Mar 2025)
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

default_num_workflow_runs=10

# shellcheck disable=SC2034,SC2154
usage_description="
Outputs the text log for a given GitHub Actions workflow run to the terminal

Fetches the last $default_num_workflow_runs runs and drops you into an interactive menu to hit enter on the one you want

Useful when the logs are too big for the UI and you have to open it in another tab which is very slow in browser

Requires GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner>/<repo> <num_workflow_runs>]"

help_usage "$@"

max_args 2 "$@"

owner_repo="${1:-}"
num_workflow_runs="${2:-$default_num_workflow_runs}"

args=()
if [ -n "$owner_repo" ]; then
    is_github_owner_repo "$owner_repo" || die "Invalid GitHub owner/repo given: $owner_repo"
    args+=(-R "$owner_repo")
fi

if ! is_int "$num_workflow_runs"; then
    usage "Second arg for number of workflow runs to fetch has to be an integer, got: $num_workflow_runs"
fi
if [ "$num_workflow_runs" -lt 1 ]; then
    usage "Second arg for number of workflow runs to fetch cannot be less than 1, got: $num_workflow_runs"
fi

if ! type -P dialog &>/dev/null; then
    timestamp "Diaglog not found in \$PATH, attempting to install via OS package manager"
    echo
    "$srcdir/../packages/install_packages.sh" dialog
    echo
fi

timestamp "Fetching last $num_workflow_runs workflow runs"
workflow_runs="$(gh run list -L "$num_workflow_runs" ${args:+"${args[@]}"})"

# header is not printed in a pipe
#header="$(head -n1 <<< "$workflow_runs")"
#workflow_runs="$(tail -n +2 <<< "$workflow_runs")"

timestamp "Generating menu items"
while read -r line; do

    # used for counting and string conversion if only a single item

    menu_items+=("$line")

    # passed to dialog because it requires args: tag1 visibletext tag2 visibletext
    # - by making the second one blank it uses the item as both the tag to be returned
    # to script as well as the visible text

    menu_tag_items+=("$line" " ")

done <<< "$workflow_runs"

if [ "${#menu_items[@]}" -eq 0 ];then
    die 'No workflow runs found!'
elif [ "${#menu_items[@]}" -eq 1 ];then
    workflow_run="${menu_items[*]}"
else
    workflow_run="$(dialog --menu "Choose which workflow run to fetch the logs for" "$LINES" "$COLUMNS" "$LINES" "${menu_tag_items[@]}" 3>&1 1>&2 2>&3)"
fi

timestamp "Parsing ID for selected workflow run: $workflow_run"
workflow_id="$(awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]{11}$/) print $i}' <<< "$workflow_run")"

if is_blank "$workflow_id"; then
    die "Failed to parse the workflow ID from the selected item"
fi

timestamp "Fetching logs for workflow ID '$workflow_id'"
gh run view "$workflow_id" ${args:+"${args[@]}"} --log
