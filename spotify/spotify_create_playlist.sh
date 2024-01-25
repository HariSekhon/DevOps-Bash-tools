#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-23 22:11:57 +0100 (Thu, 23 Jul 2020)
#
#  https://github.com/HariSekhon/Spotify-Playlists
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
Creates a Spotify playlist

By default the created playlist will be public

If SPOTIFY_PRIVATE=1 is set in the environment then the created playlist will be private

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<playlist_name>"

help_usage "$@"

min_args 1 "$@"

playlist="$1"
shift || :

public=true

if [ -n "${SPOTIFY_PRIVATE:-}" ]; then
    public=false
fi

# creating a playlist requires an authorized token
export SPOTIFY_PRIVATE=1

spotify_token

spotify_user

# $spotify_user is defined by spotify_user() from library
# shellcheck disable=SC2154
url_path="/v1/users/$spotify_user/playlists"

"$srcdir/spotify_api.sh" "$url_path" -X POST -H "Content-Type: application/json" -d "{ \"name\": \"$playlist\", \"public\": $public }"
