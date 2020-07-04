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
usage_args="<playlist> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Backs up a given public Spotify playlists for a given user to text files in both Spotify and human readable formats

Spotify track URI format can be copied and pasted back in to Spotify to restore a playlist to a previous state
(for example if you accidentally deleted a track and didn't do an immediate Ctrl-Z / Cmd-Z)

Requires \$SPOTIFY_USER be set in the environment or else given as the second arg

Requires \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET to be defined in the environment

Caveat: due to limitations of the Spotify API, this only works for public playlists
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

min_args 1 "$@"

spotify_user="${SPOTIFY_USER:-}"

playlist="$1"

shift || :

if [ -z "$spotify_user" ]; then
    usage "\$SPOTIFY_USER not defined"
fi

if [ -n "${SPOTIFY_BACKUP_DIR:-}" ]; then
    backup_dir="$SPOTIFY_BACKUP_DIR"
elif [[ "$PWD" =~ playlist ]]; then
    backup_dir="$PWD"
else
    backup_dir="$PWD/playlists"
fi
backup_dir_spotify="$backup_dir/spotify"

mkdir -vp "$backup_dir"

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token.sh")"
    export SPOTIFY_ACCESS_TOKEN
fi

playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist" "$@")"
playlist_name="$("$srcdir/spotify_playlist_id_to_name.sh" "$playlist_id" "$@")"

echo -n "$playlist_name "

filename="$("$srcdir/spotify_playlist_to_filename.sh" <<< "$playlist_name")"

echo -n "=> URIs => "
"$srcdir/spotify_playlist_tracks_uri.sh" "$playlist_id" "$@" > "$backup_dir_spotify/$filename"

echo -n 'OK => Tracks => '
"$srcdir/spotify_playlist_tracks.sh" "$playlist_id" "$@" > "$backup_dir/$filename"

echo 'OK'
