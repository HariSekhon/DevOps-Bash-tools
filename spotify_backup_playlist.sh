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

# shellcheck disable=SC1090
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Backs up a given public Spotify playlists for a given user to text files in both Spotify and human readable formats

Spotify track URI format can be copied and pasted back in to Spotify to restore a playlist to a previous state
(for example if you accidentally deleted a track and didn't do an immediate Ctrl-Z / Cmd-Z)

For public playlists, \$SPOTIFY_USER be set in the environment
For private playlists, the user is inferred from the authorized token

$usage_auth_msg

Caveat: due to limitations of the Spotify API, by default works on public playlists.
For private playlists you must export SPOTIFY_PRIVATE=1 and preferably pre-generate the token in your shell to prevent repeated web authorization pop-ups:

export SPOTIFY_ACCESS_TOKEN=\"\$(\"$srcdir/spotify_api_token.sh\")\"
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

playlist="$1"
if [ "$playlist" = liked ] || [ "$playlist" = saved ]; then
    playlist="Liked Songs"
fi
liked(){
    [ "$playlist" = "Liked Songs" ]
}

shift || :

spotify_user

if not_blank "${SPOTIFY_BACKUP_DIR:-}"; then
    backup_dir="$SPOTIFY_BACKUP_DIR"
elif [[ "$PWD" =~ playlist ]]; then
    backup_dir="$PWD"
else
    backup_dir="$PWD/playlists"
fi
backup_dir_spotify="$backup_dir/spotify"
if liked; then
    playlist_name="Liked Songs"
fi

mkdir -vp "$backup_dir"
mkdir -vp "$backup_dir_spotify"

if liked; then
    export SPOTIFY_PRIVATE=1
fi
spotify_token

if liked; then
    echo -n "$playlist_name "

    filename="$("$srcdir/spotify_playlist_to_filename.sh" <<< "$playlist_name")"

    echo -n "=> URIs => "
    "$srcdir/spotify_liked_tracks_uri.sh" "$@" > "$backup_dir_spotify/$filename"

    echo -n 'OK => Tracks => '
    "$srcdir/spotify_liked_tracks.sh" "$@" > "$backup_dir/$filename"
else
    playlist_id="$("$srcdir/spotify_playlist_name_to_id.sh" "$playlist" "$@")"
    playlist_name="$("$srcdir/spotify_playlist_id_to_name.sh" "$playlist_id" "$@")"

    echo -n "$playlist_name "

    filename="$("$srcdir/spotify_playlist_to_filename.sh" <<< "$playlist_name")"

    echo -n "=> URIs => "
    "$srcdir/spotify_playlist_tracks_uri.sh" "$playlist_id" "$@" > "$backup_dir_spotify/$filename"

    echo -n 'OK => Tracks => '
    "$srcdir/spotify_playlist_tracks.sh" "$playlist_id" "$@" > "$backup_dir/$filename"
fi

echo 'OK'
