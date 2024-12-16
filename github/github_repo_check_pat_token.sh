#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-12-16 13:38:59 +0700 (Mon, 16 Dec 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Checks the given PAT token can access the given GitHub repo

Useful to test the PAT token for integrations like ArgoCD

The token can be given as a second arg or it infers it from one of the environment varibles in this order of precedence:

    \$GH_TOKEN
    \$GITHUB_TOKEN
    \$GITHUB_PASSWORD
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner>/<repo> [<token>]"

help_usage "$@"

min_args 1 "$@"
max_args 2 "$@"

owner_repo="$1"

if ! is_github_owner_repo "$owner_repo"; then
    die "Invalid GitHub <owner>/<repo> given, failed regex match: $owner_repo"
fi

if [ $# -gt 1 ]; then
    export GH_TOKEN="$2"
fi

# follows what github_api.sh infers to use as the token
token="${GH_TOKEN:-${GITHUB_TOKEN:-${GITHUB_PASSWORD:-}}}"
token="${token:(-4)}"
# or with a preceding space but this is not obvious and someone might remove the space, exposing the token to the screen
#token="${token: -4}"

if is_blank "$token"; then
    die "GH_TOKEN is blank and no second arg given for token"
fi

echo "TOKEN: $token"
echo
echo -n "Login: "
"$srcdir/github_api.sh" /user | jq -r '.login'
echo
timestamp "Checking PAT token can access repo '$owner_repo'"
echo
result="$("$srcdir/github_api.sh" "/repos/$owner_repo" | jq -r '.full_name')"
if [ "$result" = null ] || is_blank "$result"; then
    die "ERROR: PAT token failed to access repo '$owner_repo'"
else
    timestamp "Successfull accessed GitHub repo: $result"
fi
