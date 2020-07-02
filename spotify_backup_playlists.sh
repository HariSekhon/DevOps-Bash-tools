#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: harisekhon
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 17:39:04 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_user> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Backs up all public spotify playlists for a given user to text files contains Spotify track URIs which can be copied and pasted back in to Spotify to restore a playlist

Requires \$SPOTIFY_USER be set in the environment or else given as the second arg

Requires \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET to be defined in the environment
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

spotify_user="${1:-${SPOTIFY_USER:-}}"

shift || :

if [ -z "$spotify_user" ]; then
    usage "\$SPOTIFY_USER not defined and no first argument given"
fi

backup_dir="${SPOTIFY_BACKUP_DIR:-$PWD/playlists/spotify}"

SECONDS=0
timestamp "Backing up Spotify playlists to $backup_dir"
echo >&2
mkdir -vp "$backup_dir"

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    export SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token.sh")"
fi

"$srcdir"/spotify_foreach_playlist.sh "echo -n '=> ' && \"$srcdir/spotify_playlist_tracks_uri.sh\" '{playlist_id}' > '$backup_dir'/\"\$(tr -d / <<< \"{playlist}\")\" $* && echo -n 'OK'" "$spotify_user" "$@"
echo >&2
timestamp "Backups finished in $SECONDS seconds"
