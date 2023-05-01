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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/ci.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Merges one Git branch into another branch in a local Git checkout

Designed to be called by a CI build system to automatically backport via merge any changes in Staging branch into Dev branch eg.

    ${0##*/} staging dev

Requires executing inside a Git SSH cloned repo and an SSH key being present on the CI Agent that executes this job.
Set the CI job to clone the repo via SSH and use the CI system's secrets mechanism for the SSH key.
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<from_branch> <to_branch>"

help_usage "$@"

num_args 2 "$@"

from_branch="$1"
to_branch="$2"

set -x

if is_CI; then
    :  # running in CI as expected
    # needed to check in
    # XXX: can edit this to your company domain and team email address
    git config user.email "platform-engineering@localhost"
    git config user.name "$(CI_name)"  # lib/ci.sh CI_name function will return something appropriate
#else
#    echo "This script is designed to only be run from CI!!"
#    exit 1
fi

# only apply to own repo
cd "$(dirname "$0")"

git config core.sparseCheckout false

git status

# doesn't exist yet
cat ~/.ssh/known_hosts || :

mkdir -pv ~/.ssh

# needed for git pull to work
ssh-keyscan github.com >> ~/.ssh/known_hosts

## needed to get list of remote branches before checking one out locally
git fetch

git checkout "$to_branch" --force
git pull --no-edit
git merge "origin/$from_branch" --no-edit

git push
