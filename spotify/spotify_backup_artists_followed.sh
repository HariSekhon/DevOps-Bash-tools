#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-07 00:30:25 +0000 (Sat, 07 Nov 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Downloads the list of Spotify artists followed

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

if is_blank "${SPOTIFY_BACKUP_DIR:-}"; then
    if [[ "$PWD" =~ playlists ]]; then
        export SPOTIFY_BACKUP_DIR="$PWD"
    else
        export SPOTIFY_BACKUP_DIR="$PWD/playlists"
    fi
fi

export SPOTIFY_PRIVATE=1

spotify_token

SECONDS=0

mkdir -pv "$SPOTIFY_BACKUP_DIR/spotify"

timestamp "Backing up Spotify artists followed to: $SPOTIFY_BACKUP_DIR/spotify/artists_followed.txt"
tmp="$(mktemp)"
"$srcdir/spotify_artists_followed_uri_name.sh" | sort -k2 -f > "$tmp"
mv -f "$tmp" "$SPOTIFY_BACKUP_DIR/spotify/artists_followed.txt"

timestamp "Stripping Spotify artists followed URIs to create: $SPOTIFY_BACKUP_DIR/artists_followed.txt"
awk '{$1=""; print}' "$SPOTIFY_BACKUP_DIR/spotify/artists_followed.txt" |
sed 's/^[[:space:]]//' > "$SPOTIFY_BACKUP_DIR/artists_followed.txt"
