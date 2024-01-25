#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-06-10 19:09:45 +0100 (Fri, 10 Jun 2022)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Checks the GitHub Actions workflows in the given Git repo checkout don't have any obvious script injection risks
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<directory>]"

help_usage "$@"

#min_args 1 "$@"

section "GitHub Actions Script Injection Check"

dir="${1:-.}"

cd "$dir"

git_root="$(git_root)"

workflow_dir="$git_root/.github/workflows"

# false positive
# shellcheck disable=SC2016
if git grep '^[[:space:]]\+run:.*${{' "$workflow_dir/"*.yaml "$workflow_dir/"*.yml; then
    echo
    die "WARNING: possible script injection vectors detected under '$workflow_dir'"
else
    section2 "GitHub Actions script injection check passed"
fi
