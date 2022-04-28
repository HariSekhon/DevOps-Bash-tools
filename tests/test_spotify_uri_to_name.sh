#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-11 19:22:31 +0100 (Sat, 11 Jul 2020)
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

# Requires $SPOTIFY_USER, $SPOTIFY_ID and $SPOTIFY_SECRET environment variables to run

cd "$srcdir/.."

URIs="
spotify:track:3VLj6KVC1ZQMF36t24hvuL
https://open.spotify.com/track/3VLj6KVC1ZQMF36t24hvuL?si=qFwFApYmQRuJ2Nqo3QyKng

spotify:artist:1J2VVASYAamtQ3Bt8wGgA6
https://open.spotify.com/artist/1J2VVASYAamtQ3Bt8wGgA6?si=wHJ4qxScSCihB8LgNbNjTQ

spotify:album:2PIXzzS8WEzv8Ws92qspEH
https://open.spotify.com/album/2PIXzzS8WEzv8Ws92qspEH?si=J_pcVRWrQc6_zJmH8P5yRg
"

for uri in $URIs; do
    ./spotify_uri_to_name.sh <<< "$uri"
    echo
    SPOTIFY_CSV=1 ./spotify_uri_to_name.sh <<< "$uri"
    echo
done

SPOTIFY_CSV=1 ./spotify_uri_to_name.sh < "../playlists/spotify/Rocky"
echo

./spotify_uri_to_name.sh "../playlists/spotify/Rocky"
echo

echo "Spotify URI to name tests SUCCEEDED"
