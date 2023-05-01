#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-26 15:50:49 +0000 (Mon, 26 Oct 2020)
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
Follows Spotify artists with N or more tracks in your Liked Songs using the Spotify API

The threshold for the number of Liked Songs for an artist to be followed defaults to 5 Liked Songs but this can be overriden using the first argument
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<threshold_number_of_Liked_Songs>"

help_usage "$@"
no_more_opts "$@"

threshold="${1:-5}"

is_int "$threshold" || usage "threshold given is not an integer"

export SPOTIFY_PRIVATE=1

spotify_token

"$srcdir/spotify_liked_artists_uri.sh" |
sort |
uniq -c |
sort -k1nr |
while read -r num uri; do
    if [ "$num" -ge 5 ]; then
        echo "$uri"
    fi
done |
"$srcdir/spotify_follow_artists.sh"
