#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-05-13 17:23:33 +0100 (Sat, 13 May 2023)
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
Revokes world writeable octal permission bit from any directory found in your \$PATH,
printing those directories whose permission bis it changes
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

tr ':' '\n' <<< "$PATH" |
while read -r directory; do
    [ -d "$directory" ] || continue
    # $sudo is assigned in lib depending on whether you have root perms or not
    # shellcheck disable=SC2154
    # try without sudo first as you'll probably be able to
    chmod -v o-w "$directory" ||
    $sudo chmod -v o-w "$directory"
done
