#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-17 17:09:17 +0000 (Tue, 17 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds the original release year of a given track or album via a search query of the top 10 results and taking the oldest release date

Especially useful to find the original dates of songs that get re-released in 'Greatest Hits' type albums
(eg. use in script to find songs from X decade regardless of which copy of the songs are in your playlist)

The search must be as specific as possible for accurate results and should use the artist:<name> specifier, eg.

    <track_name> artist:<artist_name>

    <album_name> artist:<artist_name>

Example:

    ${0##*/} artist:the beloved track:sweet harmony

    ${0##*/} sweet harmony artist:the beloved

    SPOTIFY_SEARCH_TYPE=album ${0##*/} happiness artist:the beloved

    SPOTIFY_SEARCH_TYPE=album ${0##*/} artist:the beloved album:happiness

For more search details see spotify_search_json.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<track_name> artist:<artist>"

help_usage "$@"

min_args 2 "$@"

export SPOTIFY_SEARCH_LIMIT=10

"$srcdir/spotify_search_json.sh" "$@" |
if [ "${SPOTIFY_SEARCH_TYPE:-track}" = track ]; then
    jq -r ".tracks.items[] | .album.release_date"
elif [ "${SPOTIFY_SEARCH_TYPE:-}" = album ]; then
    jq -r ".albums.items[] | .release_date"
else
    die "unsupported SPOTIFY_SEARCH_TYPE='$SPOTIFY_SEARCH_TYPE' - must be either track or album"
fi |
sort |
head -n1 |
sed 's/-.*$//'
