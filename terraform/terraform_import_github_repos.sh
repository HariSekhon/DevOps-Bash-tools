#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-25 18:14:24 +0000 (Fri, 25 Feb 2022)
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
Finds all github_repository references in ./*.tf code not in Terraform state and imports them

Requires the github_repository identifiers in *.tf code to match the GitHub repo name, which does not work with repos which have dots in them eg. '.github'. Those rare exceptions must be imported manually.

If \$TERRAFORM_PRINT_ONLY is set to any value, prints the commands to stdout to collect so you can check, collect into a text file or pipe to a shell or further manipulate, ignore errors etc.


Requires Terraform to be installed and configured


See Also:

    github_repos_not_in_terraform.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

dir="${1:-.}"

cd "$dir"

timestamp "getting terraform state"
terraform_state_list="$(terraform state list)"
echo >&2

timestamp "getting github repos from $PWD/*.tf code"
grep -E '^[[:space:]]*resource[[:space:]]+"github_repository"' ./*.tf |
awk '{gsub("\"", "", $3); print $3}' |
while read -r repo; do
    echo >&2
    if grep -q "github_repository\\.$repo$" <<< "$terraform_state_list"; then
        echo "repository '$repo' already in terraform state, skipping..." >&2
        continue
    fi
    cmd=(terraform import "github_repository.$repo" "$repo")
    timestamp "${cmd[*]}"
    if [ -z "${TERRAFORM_PRINT_ONLY:-}" ]; then
        "${cmd[@]}"
    fi
done
