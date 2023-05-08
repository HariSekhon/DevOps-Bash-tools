#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-15 08:58:02 +0000 (Sat, 15 Jan 2022)
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
Finds all unique file paths in Git history

Useful for prepraring to 'git filter-branch' eg. for repo splicing

Must be run from within a git repository, assumes the 'git' command is installed and in the \$PATH

If you only want current files, use instead 'git ls-files'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

# technically --all isn't that relevant to git filter-branch as it'll list things on other branches, but in terms of listing all files in history, it's more correct to include it as it won't break filter-branch derived usage
# -e '^[[:alpha:]]+:' filters out Author: , Date: , Merge: etc.
git log --all --name-only --no-color |
grep -Ev -e '^commit' -e '^[[:alpha:]]+:' -e '^Date:' -e '^[[:space:]]' -e '^[[:space:]]*$' |
sort -u
