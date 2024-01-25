#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-11 11:47:26 +0000 (Fri, 11 Feb 2022)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates an AWS user, generates and downloads an access key and uploads it to the given GitHub repo

AWS Access Keys are stored/staged in ~/.aws/keys/ - so re-running this from a new account/machine will have no choice but to recreate the access keys and upload the new key as the secret key is only available once at creation time

Requires AWS CLI and GitHub CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<owner>/<repo> <group_or_policy_name>"

help_usage "$@"

num_args 2 "$@"

owner_repo="$1"
group_or_policy="$2"

if ! is_github_owner_repo "$owner_repo"; then
    die "Invalid GitHub owner/repo given: $owner_repo"
fi

#owner="${owner_repo%/*}"
repo="${owner_repo##*/}"

#if ! gh repo list "$owner" --json name -q ".[] | select(.name == \"$repo\") | .name" | grep -Fxq "$repo"; then
if ! gh repo view "$owner_repo" >/dev/null; then
    die "GitHub repo '$owner_repo' was not found!"
fi

#aws_account_id="$(aws sts get-caller-identity --query Account --output text)"
aws_account_id="$(aws_account_id)"

keyfile=~/.aws/keys/"${repo}_${aws_account_id}_accessKeys.csv"

user="github-actions-$repo"

"$srcdir/../aws/aws_cli_create_credential.sh" "$user" "$group_or_policy" "$keyfile"
"$srcdir/../aws/aws_csv_creds.sh" "$keyfile" |
"$srcdir/github_actions_repo_set_secret.sh" "$owner_repo"
