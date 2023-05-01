#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 09:30:53 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://developer.spotify.com/documentation/web-api/reference/playlists/get-list-users-playlists/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns the list of Spotify playlists

Output Format:

<playlist_id>   <playlist_name>

By default returns only public playlists owned by given Spotify user

\$SPOTIFY_USER must be defined in environment or given as first arg unless \$SPOTIFY_PRIVATE=1 is set, in which case it's inferred from the auth token

Gets public playlists by default
To also get private playlists - export SPOTIFY_PRIVATE=1
To get only private playlists - export SPOTIFY_PRIVATE_ONLY=1
To get only public playlists  - export SPOTIFY_PUBLIC_ONLY=1

To also get followed playlists - export SPOTIFY_PLAYLISTS_FOLLOWED=1
To get only followed playlists - export SPOTIFY_PLAYLISTS_FOLLOWED_ONLY=1

$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_user> [<curl_options>]"

help_usage "$@"

if [ -n "${SPOTIFY_PLAYLISTS_FOLLOWED_ONLY:-}" ]; then
    export SPOTIFY_PLAYLISTS_FOLLOWED=1
fi

if [ -n "${SPOTIFY_PRIVATE_ONLY:-}" ]; then
    export SPOTIFY_PRIVATE=1
fi

spotify_user="${1:-${SPOTIFY_USER:-}}"

# will infer from token if $SPOTIFY_PRIVATE=1
spotify_user

if is_blank "$spotify_user"; then
    # /v1/me/playlists gets an authorization error and '/v1/users/me/playlists' returns the wrong user, an actual literal user called 'me'
    #user="me"
    usage "user not specified"
fi

shift || :

# redirects to fetching your own playlists instead of the named user if you happen to have the a stronger spotify private access token
#if not_blank "${SPOTIFY_PRIVATE:-}"; then
#    # /v1/me/playlists gets an authorization error and '/v1/users/me/playlists' returns the wrong user, an actual literal user called 'me'
#    # $limit/$offset defined in lib/spotify.sh
#    # shellcheck disable=SC2154
#    url_path="/v1/me/playlists?limit=$limit&offset=0"  # never use $offset - it will prevent playlists being found
#else
    # $limit/$offset defined in lib/spotify.sh
    # shellcheck disable=SC2154
    url_path="/v1/users/$spotify_user/playlists?limit=$limit&offset=0"  # never use $offset
#fi

output(){
    jq '.items[]' <<< "$output" |
    if not_blank "${SPOTIFY_PUBLIC_ONLY:-}"; then
        jq 'select(.public == true)'
    elif not_blank "${SPOTIFY_PRIVATE_ONLY:-}"; then
        jq 'select(.public != true)'
    else
        cat
    fi |
    if [ -n "${SPOTIFY_PLAYLISTS_FOLLOWED_ONLY:-}" ]; then
        jq "select(.owner.id != \"$spotify_user\")"
    elif [ -n "${SPOTIFY_PLAYLISTS_FOLLOWED:-}" ]; then
        cat
    else
        jq "select(.owner.id == \"$spotify_user\")"
    fi |
    jq -r "[.id, .name] | @tsv"
}

spotify_token

while not_null "$url_path"; do
    output="$("$srcdir/spotify_api.sh" "$url_path" "$@")"
    #die_if_error_field "$output"
    url_path="$(get_next "$output")"
    output
done
