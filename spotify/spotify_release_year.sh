#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-17 17:09:17 +0000 (Tue, 17 Nov 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Finds the original release year of a given track or album via a search query of the top 10 results and taking the oldest release date

Especially useful to find the original dates of songs that get re-released in 'Greatest Hits' type albums
(eg. use in script to find songs from X decade regardless of which copy of the songs are in your playlist)

The search must be as specific as possible for accurate results and should include both the artist name as well as the track/album,
preferably with the artist specified as artist:<name> eg.

    <track_name> artist:<artist_name>

    <album_name> artist:<artist_name>

Examples:

    Tracks:

        ${0##*/} sweet harmony artist:the beloved

        ${0##*/} artist:the beloved track:sweet harmony

        ${0##*/} kylie on a night like this

    Albums:

        SPOTIFY_SEARCH_TYPE=album ${0##*/} happiness artist:the beloved

        SPOTIFY_SEARCH_TYPE=album ${0##*/} artist:the beloved album:happiness

For more details on search query syntax see spotify_search_json.sh


Caveat: this is only as accurate as Spotify's data which is usually fairly good, but if Spotify has only managed to license a song via a later compilation album then we can only report the earliest release date which may not be the real original release for a classic. An example of this is

    artist:\"Carl Douglas\"  track:\"Kung Fu Fighting\"

Which I know is a 70s song but Spotify only has it on compilations dated 2001 onwards, leading to an incorrect result in that rare case.

In a rare case you may need to tune the number of results from which the original date is inferred to more than 10 using the SPOTIFY_SEARCH_LIMIT environment variable but in my testing the first 10 results have always contained the original version from which to infer the oldest date,
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<track_name> artist:<artist>"

help_usage "$@"

min_args 2 "$@"

export SPOTIFY_SEARCH_LIMIT="${SPOTIFY_SEARCH_LIMIT:-10}"

"$srcdir/spotify_search_json.sh" "$@" |
if [ "${SPOTIFY_SEARCH_TYPE:-track}" = track ]; then
    jq -r ".tracks.items[] | .album.release_date"
elif [ "${SPOTIFY_SEARCH_TYPE:-}" = album ]; then
    jq -r ".albums.items[] | .release_date"
else
    die "unsupported SPOTIFY_SEARCH_TYPE='$SPOTIFY_SEARCH_TYPE' - must be either track or album"
fi |
# lexical oldest of YYYY or YYYY-mm-dd will be first
sort |
head -n1 |
# a few release dates have higher granularity, strip everything after the year YYYY-mm-dd
sed 's/-.*$//' |
# this is only here to make the exit code error 1 if nothing is found
grep --color=no .
