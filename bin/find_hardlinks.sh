#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-28 01:16:44 +0000 (Wed, 28 Feb 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Finds all hardlinks to a given file by searching the mount point for the same inode number of a file
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<filename>"

help_usage "$@"

num_args 1 "$@"

filename="$1"

inode_number="$(stat -f "%i" "$filename")"

mount_point="$(df "$filename" | awk '{print $NF}' | tail -n 1)"

find "$mount_point" -xdev -inum "$inode_number" -print
