#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 09:30:53 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-list-users-playlists/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_user> [<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns the list of Spotify playlists

Output Format:

<playlist_id>   <playlist_name>

By default returns only public playlists owned by given Spotify user

Set \$SPOTIFY_PLAYLISTS_FOLLOWED in the environment to return all followed playlists as well

\$SPOTIFY_USER can be used from the evironment if no first argument is given

To get private playlists set \$SPOTIFY_PRIVATE=1 and don't specify the spotify user which is inferred from the token
used

Due to quirks of the Spotify API, this requires an interactive web authorization pop-up
or \$SPOTIFY_ACCESS_TOKEN in the environment. To prevent repeated pop-ups, set once an hour in your shell like so:

export SPOTIFY_ACCESS_TOKEN=\"\$(\"$srcdir/spotify_api_token_interactive.sh\")\"

If you 've exported a non-authorized \$SPOTIFY_ACCESS_TOKEN in your environment (eg. from spotify_api_token.sh),
then this script will fail with a 401 unauthorized error

Requires \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment if SPOTIFY_ACCESS_TOKEN is unset
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

if [ -n "${1:-}" ]; then
    user="$1"
elif [ -n "${SPOTIFY_USER:-}" ]; then
    user="$SPOTIFY_USER"
else
    # /v1/me/playlists gets an authorization error and '/v1/users/me/playlists' returns the wrong user, an actual literal user called 'me'
    #user="me"
    usage "user not specified"
fi

shift || :

offset="${SPOTIFY_OFFSET:-0}"
limit="${SPOTIFY_LIMIT:-50}"

if [ -n "${SPOTIFY_PRIVATE:-}" ]; then
    # /v1/me/playlists gets an authorization error and '/v1/users/me/playlists' returns the wrong user, an actual literal user called 'me'
    url_path="/v1/me/playlists?limit=$limit&offset=$offset"
else
    url_path="/v1/users/$user/playlists?limit=$limit&offset=$offset"
fi

output(){
    if [ -n "${SPOTIFY_PRIVATE:-}" ]; then
        jq -r ".items[] | select(.public != true) | [.id, .name] | @tsv" <<< "$output"
    # now enforcing only public playlists to avoid accidentally backing up private playlists if $SPOTIFY_ACCESS_TOKEN
    # in the environment happens to be an authorized token and therefore skips generating the right token below
    elif [ -n "${SPOTIFY_PLAYLISTS_FOLLOWED:-}" ]; then
        jq -r ".items[] | select(.public == true) | [.id, .name] | @tsv"
    else
        jq -r ".items[] | select(.public == true) | select(.owner.id == \"$user\") | [.id, .name] | @tsv"
    fi <<< "$output"
}

get_next(){
    jq -r '.next' <<< "$output"
}

if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ]; then
    SPOTIFY_ACCESS_TOKEN="$("$srcdir/spotify_api_token.sh")"
    export SPOTIFY_ACCESS_TOKEN
fi

while [ -n "$url_path" ] && [ "$url_path" != null ]; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    # shellcheck disable=SC2181
    if [ $? != 0 ] || [ "$(jq -r '.error' <<< "$output")" != null ]; then
        echo "$output" >&2
        exit 1
    fi
    url_path="$(get_next)"
    output
done
