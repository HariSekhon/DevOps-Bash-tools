#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-26 22:49:25 -0600 (Wed, 26 Nov 2025)
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
Move files from one volume to another atomically with partial resume support for large files and
removes the source files once they're copied

Useful to migrate data from one disk to another

If the CHECKSUM environment variable is set to any non-blank value
then also checksums the files on both ends (very slow)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<source_directory> <destination_directory>"

help_usage "$@"

num_args 2 "$@"

src="$1"
dest="$2"

timestamp "Starting resumable rsync to move files from '$src' to '$dest'"
echo >&2
rsync -avh \
      --progress \
      --info=progress2,stats \
      --partial \
      --remove-source-files "$src/" "$dest/" \
      ${CHECKSUM:+--checksum}
echo >&2

timestamp "Move complete, deleting empty directories from '$src'"
echo >&2
find "$src" -type d -empty -delete
echo >&2

timestamp "Atomic move completed"
