#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-27 13:17:04 +0000 (Mon, 27 Dec 2021)
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
Deletes all empty directories under the current or given directory

On Mac pre-deletes .DS_Store files to prevent otherwise empty directories from being retained

Tested on Mac OS X
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<directory>]"

help_usage "$@"

#min_args 1 "$@"

starting_directory="${1:-.}"

# -d / -depth = depth first traversal - avoids find removing the directory and then trying to recurse it, causing the following error:
# find: ./somedir: No such file or directory
# -delete implies -depth but it's riskier because although more efficient avoiding forks for each empty dir, if the selector is wrong such as missing the - before -type you'll lose files / data
#find "$starting_directory" -type d -empty -delete

# Mac's rmdir command doesn't have a --verbose switch for feedback, so use GNU version instead
if is_mac; then
    find "$starting_directory" -type f -name .DS_Store -delete
    find "$starting_directory" -type d -empty -depth -exec grmdir -v {} \;
else
    find "$starting_directory" -type d -empty -depth -exec rmdir -v {} \;
fi
