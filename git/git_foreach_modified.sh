#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-02 19:54:09 +0100 (Tue, 02 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# access to useful functions and aliases
# shellcheck disable=SC1090,SC1091
. "$srcdir/.bash.d/aliases.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/.bash.d/functions.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/.bash.d/git.sh"

# shellcheck disable=SC2034
usage_description="
Runs any arguments as a command against each file with a Git modified status

The filename will be appended to the end of each command in each iteration
"

# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

for filename in $(git status --porcelain | awk '/^.M/{print $NF}'); do
    "$@" "$filename"
done
