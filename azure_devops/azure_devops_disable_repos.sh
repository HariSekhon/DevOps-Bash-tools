#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-09-13 18:05:20 +0100 (Mon, 13 Sep 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/update?view=azure-devops-rest-6.1#disable-repository

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Disables one or more given Azure DevOps repos (for after a migration to GitHub to prevent writes to the wrong server being left behind)

For authentication and other details see:

    azure_devops_api.sh --help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<organization> <project> <repo> [<repo2> <repo3> ...]"

help_usage "$@"

min_args 3 "$@"

org="$1"
project="$2"
shift || :
shift || :

disable_repo(){
    local repo="$1"
    local id
    timestamp "getting repo id for  Azure DevOps organization '$org' project '$project' repo '$repo'"
    set +euo pipefail
    response="$("$srcdir/azure_devops_api.sh" "/$org/$project/_apis/git/repositories/$repo")"
    # shellcheck disable=SC2181
    if [ $? != 0 ]; then
        timestamp "repo not found or already disabled, skipping..."
        return 0
    fi
    set -euo pipefail
    id="$(jq -e -r .id <<< "$response")"
    timestamp "disabling Azure DevOps organization '$org' project '$project' repo '$repo'"
    "$srcdir/azure_devops_api.sh" "/$org/$project/_apis/git/repositories/$id?api-version=6.1-preview.1" -X PATCH -d '{"isDisabled": true}' |
    jq -e -r '[ "Disabled: ", .isDisabled ] | @tsv'
}

for repo in "$@"; do
    disable_repo "$repo"
done
