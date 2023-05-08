#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-26 19:00:10 +0000 (Wed, 26 Jan 2022)
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
. "$srcdir/lib/git.sh"

ALLOW_FILE="$srcdir/.github/workflows/actions-allowed.txt"

# shellcheck disable=SC2034,SC2154
usage_description="
Allows select 3rd party GitHub Actions in the given repo using the GitHub API

If you have an Organization, I recommend you set this organization-wide instead, but for individual users this is handy to automate tightenting up your security

The list of actions is taken from the adjacent file '${ALLOW_FILE#$srcdir/}'

See Also:

    github_actions_repos_lockdown.sh - applies this to all repos
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<user>/<repo>"

help_usage "$@"

#min_args 1 "$@"

repo="${1:-}"

if [ -z "$repo" ]; then
    repo="$(git_repo)"
fi

repo="$(perl -pne 's|^https://github.com/||i' <<< "$repo")"
repo="${repo##/}"

actions_allowed="$(sed 's/#.*//;
                        s/^[[:space:]]*//;
                        s/[[:space:]]*$//;
                        /^[[:space:]]*$/d;' \
                        "$ALLOW_FILE")"

if [ -z "$actions_allowed" ]; then
    die "No 3rd party actions found in the allow file '$ALLOW_FILE'"
fi

timestamp "Enabling the following 3rd party GitHub Actions on repo '$repo':"
echo
echo "$actions_allowed"
echo

# convert to array of strings for the API
#actions_allowed_json_array="$(printf "[%s]" "$(while read -r action; do echo "\"$action\", "; done <<< "$actions_allowed" | sed 's/, //')")"

actions_allowed_json_array="["
while read -r action; do
    actions_allowed_json_array+="\"$action\", "
done <<< "$actions_allowed"
actions_allowed_json_array="${actions_allowed_json_array%, }"
actions_allowed_json_array+="]"

"$srcdir/github_api.sh" "/repos/$repo/actions/permissions/selected-actions" -X PUT -d "{\"patterns_allowed\": $actions_allowed_json_array}"  # don't quote array, it contains the quotes already
