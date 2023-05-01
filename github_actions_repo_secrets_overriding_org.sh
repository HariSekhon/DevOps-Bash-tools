#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-14 17:16:30 +0000 (Mon, 14 Feb 2022)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Finds any GitHub Actions secrets in the current or given repo that are overriding Organization-level secrets

Useful to audit across repos when combined with github_foreach_repo.sh

Requires GitHub CLI to be installed and configured with a token with permissions to the organization as well as the repo
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner>/<repo>"

help_usage "$@"

#min_args 1 "$@"

owner_repo="${1:-}"
# set the default outside of the ${1:-} to avoid issues with braces and escaping them becoming literal slashes
if is_blank "$owner_repo"; then
    owner_repo='{owner}/{repo}'
fi

org="$(gh api "/repos/$owner_repo" -q '.organization.login')"

if [ -z "$org" ]; then
    die "Repo is not owned by an organization"
fi

org_secrets="$(gh api "/orgs/$org/actions/secrets" | jq -r '.secrets[].name')"

if [ -z "$org_secrets" ]; then
    warn "No organization secrets found"
    exit 0
fi

repo_secrets="$(gh api "/repos/$owner_repo/actions/secrets" | jq -r '.secrets[].name')"

while read -r repo_secret; do
    [ -z "$repo_secret" ] && continue
    if grep -Fxq "$repo_secret" <<< "$org_secrets"; then
        echo "$repo_secret"
    fi
done <<< "$repo_secrets"
