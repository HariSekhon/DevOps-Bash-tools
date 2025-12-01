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
Moves directory trees resumably and removes the source directories as they're copied over

Useful to migrate data from one disk to another

If the CHECKSUM environment variable is set to any non-blank value
then also checksums the files on both ends (very slow)

Shows the overall % of files transferred and the MB/s data transfer rate

Uses rsync so the source and destination directories follows the same principle, do not suffix a slash
unless you want the contents to be copied without the top level directory name

To see the overall volume size transfer progress, in another terminal you can run:

    watch df -m /Volumes/One /Volumes/Two
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
      --info=progress2,stats \
      --remove-source-files "$src" "$dest" \
      --exclude=.Spotlight-V100 \
      --exclude=.fseventsd \
      ${CHECKSUM:+--checksum}
      # no point in partial resume if you need to --apend-verify checksum
      #--partial \
      #--no-whole-file \
      #--append-verify \
echo >&2

timestamp "Move complete, deleting empty directories from '$src'"
echo >&2
if is_mac; then
    find "$src" -type d -exec "$srcdir/mac_rmdir.sh" {} \;
fi
find "$src" -type d -empty -delete
echo >&2

timestamp "Directory tree move completed"
