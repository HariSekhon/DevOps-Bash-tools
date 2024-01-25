#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: < <(find ../playlists/spotify/ -type f)
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 17:39:04 +0100 (Wed, 24 Jun 2020)
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

# shellcheck disable=SC2034
usage_description="
Normalizes a Spotify playlist filename provided as arg(s) or stdin to an original playlist name

This is used because playlists with slashes have them converted to unicode equivalent by spotify_playlist_to_filename.sh, so when searching for playlists in spotify_playlist_name_to_id.sh, I use this script to reverse the process to allow for using auto-completed filenames as playlist names and still having everything resolve correctly
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_filename>"

help_usage "$@"

normalize(){
    # strip folder name
    sed 's,.*/,,' |
    # replace unicode forward slash needed for storing as filename with the original ascii version in the real playlist name
    tr '∕' '/'
}

if not_blank "$*"; then
    normalize <<< "$*"
else
    normalize  # from stdin
fi
