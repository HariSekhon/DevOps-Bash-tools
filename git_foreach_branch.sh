#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-11-21 10:43:47 +0100 (Tue, 21 Nov 2017)
#
#  https://github.com/HariSekhon/Dockerfiles
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

# shellcheck source=lib/git.sh
. "$srcdir/lib/git.sh"

# access to useful functions and aliases
# shellcheck disable=SC1090,SC1091
#. "$srcdir/.bash.d/aliases.sh"
#. "$srcdir/.bash.d/functions.sh"
. "$srcdir/.bash.d/git.sh"

# shellcheck disable=SC2034
usage_description="
Run a command against each Git branch in the current repo checkout

Checks out each branch and runs the command, before returning to the original branch

If the command fails on a branch, this script will exit and leave you checked out on that branch

One use case for this is merging your trunk branch into all your feature branches in an automated manner

This is powerful so use carefully!
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

foreachbranch "$@"
