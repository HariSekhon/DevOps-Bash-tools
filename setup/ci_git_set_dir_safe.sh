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

# Necessary for some CI/CD systems like Azure DevOps Pipelines which have incorrect ownership on the git checkout dir triggering this error:
#
#    fatal: detected dubious ownership in repository at '/code/sql'

# standalone script without lib dependency so it can be called directly from bootstrapped CI before submodules, since that is the exact problem that needs to be solved to allow CI/CD systems with incorrect ownership of the checkout directory to be able to checkout the necessary git submodules

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dir="${1:-$srcdir/..}"

cd "$dir"

echo "Setting directory as safe: $PWD"
git config --global --add safe.directory "$PWD"

while read -r submodule_dir; do
    dir="$PWD/$submodule_dir"
    echo "Setting directory as safe: $dir"
    git config --global --add safe.directory "$dir"
done < <(git submodule | awk '{print $2}')

echo "Done"
