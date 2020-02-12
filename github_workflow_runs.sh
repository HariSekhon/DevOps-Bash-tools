#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-12 16:21:52 +0000 (Wed, 12 Feb 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

usage(){
    cat <<EOF
$*

Script to get GitHub Workflow runs for a given Workflow ID (or name.yaml) via the API

Workflow ID can be either a number (see output of adjacent github_workflows.sh), or the name of the workflow yaml file, with or without the .yaml extension

If no repo arg is given and is inside a git repo then takes determines the repo from the first git remote listed

\$REPO and \$WORKFLOW_ID environment variables are also supported with positional args taking precedence

usage: ${0##*/} <workflow_id> [<repo>]

EOF
    exit 3
}

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
    repo="$(git remote -v 2>/dev/null | awk '{print $2}' | head -n1 | sed 's/[[:alnum:]]*@//; s,.*github.com[/:],,')"
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

USER="${GITHUB_USER:-${USERNAME:-${USER}}}"
PASSWORD="${GITHUB_PASSWORD:-${GITHUB_TOKEN:-${PASSWORD}}}"

if ! [[ $repo =~ / ]]; then
    repo="$USER/$repo"
fi

#if [ -n "${PASSWORD:-}"  ]; then
#    echo "using authenticated access" >&2
#fi

eval "$srcdir/curl_auth.sh" -sS --connect-timeout 3 "${CURL_OPTS:-}" "https://api.github.com/repos/$repo/actions/workflows/$workflow_id/runs"  # | | jq '.workflow_runs[0:10]'
