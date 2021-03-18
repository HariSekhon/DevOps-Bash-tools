#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Mon Feb 1 11:29:15 2021 +0000
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
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Merges Git 'staging' branch to 'dev' branch for CI automated backports

Designed to be called only by a CI build system to automatically keep Dev branch up to date with Staging branch
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

set -x

if is_CI; then
    :  # running in CI as expected
else
    echo "This script is designed to only be run from CI!!"
    exit 1
fi

# only apply to own repo
cd "$(dirname "$0")"

# needed to check in
git config user.email "platform-engineering@localhost"
git config user.name "Jenkins"

git config core.sparseCheckout false

git status

# doesn't exist yet
cat ~/.ssh/known_hosts || :

mkdir -pv ~/.ssh

# needed for git pull to work
ssh-keyscan github.com >> ~/.ssh/known_hosts

# needed to get remotes to checkout staging
git pull --no-edit

git checkout staging --force
git pull --no-edit

git checkout dev --force
git pull --no-edit
git merge staging --no-edit

git push
