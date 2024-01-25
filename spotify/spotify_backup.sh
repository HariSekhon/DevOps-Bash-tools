#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-02 19:11:12 +0100 (Thu, 02 Jul 2020)
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
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
One-touch Spotify Backup of all or selected Spotify playlists

If playlist args are given then backs up only those playlists

Without args, backs up all public playlists

$usage_playlist_help

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<playlist> <playlist2> ...]"

help_usage "$@"

if is_blank "${SPOTIFY_BACKUP_DIR:-}"; then
    if [[ "$PWD" =~ playlists ]]; then
        export SPOTIFY_BACKUP_DIR="$PWD"
    else
        export SPOTIFY_BACKUP_DIR="$PWD/playlists"
    fi
fi

section "Running Spotify Playlists Backup"

spotify_token

if [ $# -gt 0 ]; then
    echo "Backing up selected playlist(s):"
    echo
    for playlist in "$@"; do
        "$srcdir/spotify_backup_playlist.sh" "$playlist"
    done
    exit 0
fi

mkdir -pv "$SPOTIFY_BACKUP_DIR/spotify"

timestamp "Dumping list of Spotify playlists to $SPOTIFY_BACKUP_DIR/spotify/playlists.txt"
"$srcdir/spotify_playlists.sh" > "$SPOTIFY_BACKUP_DIR/spotify/playlists.txt"
echo >&2

timestamp "Stripping spotify playlist IDs from $SPOTIFY_BACKUP_DIR/spotify/playlists.txt => $SPOTIFY_BACKUP_DIR/playlists.txt"
sed 's/^[^[:space:]]*[[:space:]]*//' "$SPOTIFY_BACKUP_DIR/spotify/playlists.txt" > "$SPOTIFY_BACKUP_DIR/playlists.txt"
echo >&2

"$srcdir/spotify_backup_playlists.sh"
