#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-03 20:07:09 +0100 (Wed, 03 Aug 2022)
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sets the current or given git directory and submodules to be marked as safe

Necessary for some CI/CD systems which have wacky permissions triggering this error:

    fatal: detected dubious ownership in repository at '/code/sql'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

#min_args 1 "$@"

dir="${1:-.}"

cd "$dir"

echo "Setting directory as safe: $PWD"
git config --global --add safe.directory "$PWD"

while read -r submodule_dir; do
    dir="$PWD/$submodule_dir"
    echo "Setting directory as safe: $dir"
    git config --global --add safe.directory "$dir"
done < <(git submodule | awk '{print $2}')

echo "Done"
