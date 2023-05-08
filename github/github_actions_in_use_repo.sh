#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: HariSekhon/DevOps-Bash-tools
#
#  Author: Hari Sekhon
#  Date: 2022-01-26 19:58:49 +0000 (Wed, 26 Jan 2022)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Finds all GitHub Actions in use in the given repo under .github/workflows/ in the default branch using the GitHub API

This is useful to combine with github_actions_repo_actions_allow.sh and github_actions_repos_lockdown.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner>/<repo>"

help_usage "$@"

min_args 1 "$@"

repo="$1"  # in owner/repo format

if ! is_github_owner_repo "$repo"; then
    usage "invalid repo format specified, expected owner/repo format"
fi

process_contents(){
    local data
    data="$(cat)"
    if [ "$(jq -r '.type' <<< "$data")" != file ]; then
        return 0
    fi
    jq -r '.content' <<< "$data" |
    base64 --decode
}

grep_github_actions(){
    # filtering out anything with .github in it as that will be a .github/workflows/file.yaml, not an action
    { grep -Eo '^[^#]+[[:space:]]uses:.+@[^#[:space:]]+' || : ; } |
    sed '
        s/^[^#]*[[:space:]]uses:[[:space:]]*//;
        s/#.*$//;
        s/[[:space:]]*$//;
        /\.github/d;
    ' |
    sort -fu
}

timestamp "Checking repo '$repo'"
# if this gets a 404 then skip there is no such dir and no workflows
if "$srcdir/github_api.sh" "/repos/$repo/contents/.github/workflows" &>/dev/null; then
    timestamp "GitHub workflows dir found, fetching file list"
    "$srcdir/github_api.sh" "/repos/$repo/contents/.github/workflows" |
    #jq -r '.[] | select(.type == "file") | .download_url' |  # this would probably only work for public repos, we need to use the API address to reuse github_api.sh
    jq -r '.[].name' |
    while read -r filename; do
        [[ "$filename" =~ \.ya?ml$ ]] || continue
        #timestamp "Checking '$repo' => ${download_url##*/}"
        timestamp "Checking '$repo' => $filename"

        # Find directly used GitHub Actions
        data="$("$srcdir/github_api.sh" "/repos/$repo/contents/.github/workflows/$filename")"
        contents="$(process_contents <<< "$data")"
        grep_github_actions <<< "$contents"

        # Find GitHub Actions in remote workflow files
        { grep -Eo '^[^#]+[[:space:]]uses:.+/.github/workflows/.+@[^#[:space:]]+' || : ; } <<< "$contents" |
        sed 's/^[^#]*[[:space:]]uses:[[:space:]]*//; s/#.*$//;' |
        while read -r reusable_workflow; do
            timestamp "Checking reusable workflow: $reusable_workflow"
            reusable_workflow="${reusable_workflow/.github/contents/.github}"
            reusable_workflow="${reusable_workflow/@/?ref=}"
            "$srcdir/github_api.sh" "/repos/$reusable_workflow" |
            process_contents |
            grep_github_actions
        done
    done
else
    timestamp "No GitHub workflows found in repo '$repo'"
fi
