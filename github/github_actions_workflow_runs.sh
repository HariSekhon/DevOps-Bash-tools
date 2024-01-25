#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: ci_ubuntu
#
#  Author: Hari Sekhon
#  Date: 2020-02-12 16:21:52 +0000 (Wed, 12 Feb 2020)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034
usage_description="
Returns GitHub Actions Workflow runs for a given Workflow ID (or name.yaml) in json format via the API

Workflow ID can be either a number (see output of adjacent github_actions_workflows.sh), or the name of the workflow yaml file, with or without the .yaml extension

If no repo arg is given and is inside a git repo then takes determines the repo from the first git remote listed

\$REPO and \$WORKFLOW_ID environment variables are also supported with positional args taking precedence
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<workflow_id> [<repo>]"

help_usage "$@"

workflow_id="${1:-${WORKFLOW_ID:-}}"

repo="${2:-${REPO:-}}"

if [ -z "$workflow_id" ]; then
    usage "workflow_id not specified"
fi

if ! [[ "$workflow_id" =~ ^[[:digit:]]+$ ]]; then
    if ! [[ "$workflow_id" =~ \.ya?ml$ ]]; then
        workflow_id="$workflow_id.yaml"
    fi
fi

if [ -z "$repo" ]; then
    repo="$(git_repo)"
fi

if [ -z "$repo" ]; then
    usage "repo not specified and couldn't determine from git remote command"
fi

for arg; do
    case "$arg" in
        -*)     usage
                ;;
    esac
done

if ! [[ $repo =~ / ]]; then
    repo="$USER/$repo"
fi

"$srcdir/github_api.sh" "/repos/$repo/actions/workflows/$workflow_id/runs"  # | | jq '.workflow_runs[0:10]'
