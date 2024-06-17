#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-20 00:26:08 +0100 (Mon, 20 Jul 2020)
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
libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$libdir/utils.sh"

offset="${SPOTIFY_OFFSET:-0}"
# conservative, some API endpoints can take 100, others 50 - this is the safe choice but will go faster for those APIs if you can set 100 where appropriate
limit="${SPOTIFY_LIMIT:-50}"

if ! [[ "$offset" =~ ^[[:digit:]]+$ ]]; then
    echo "Invalid \$SPOTIFY_OFFSET = $offset found in environment" >&2
    exit 1
fi

if ! [[ "$limit" =~ ^[[:digit:]]+$ ]]; then
    echo "Invalid \$SPOTIFY_LIMIT = $limit found in environment" >&2
    exit 1
fi

spotify_token(){
    # tokens with authorization have length 281, tokens without 219, so if there is an unauthorized token in the environment, regenerate it to avoid 401 errors
    # [ -a ] works in bash and is the most concise way of doing this
    # shellcheck disable=SC2166
    if [ -z "${SPOTIFY_ACCESS_TOKEN:-}" ] ||
       [ -n "${SPOTIFY_PRIVATE:-}" -a "${#SPOTIFY_ACCESS_TOKEN}" -lt 280 ]; then
        SPOTIFY_ACCESS_TOKEN="$("$libdir/../spotify_api_token.sh")"
    fi
    export SPOTIFY_ACCESS_TOKEN
}

spotify_user(){
    spotify_user="${spotify_user:-${SPOTIFY_USER:-}}"
    if [ -z "$spotify_user" ]; then
        if [ -n "${SPOTIFY_PRIVATE:-}" ]; then
            spotify_user="$(SPOTIFY_PRIVATE=1 "$libdir/../spotify_api.sh" "/v1/me" | jq -r '.id')"
        else
            usage "\$SPOTIFY_USER not defined, and not using SPOTIFY_PRIVATE to auto-infer user from an authorized token"
        fi
    fi
}

# used by client scripts
# shellcheck disable=SC2034
usage_auth_msg="Requires \$SPOTIFY_ACCESS_TOKEN, or \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment"

# srcdir defined in client scripts
# shellcheck disable=SC2034,SC2154
usage_token_private="export SPOTIFY_ACCESS_TOKEN=\"\$(SPOTIFY_PRIVATE=1 '$libdir/../spotify_api_token.sh')\""

# shellcheck disable=SC2034
usage_playlist_help="See spotify_playlists.sh --help for details on accessing private playlists"

# shellcheck disable=SC2034
usage_auth_help="See spotify_api_token.sh --help for authentication details and setting up your SPOTIFY_ID, SPOTIFY_SECRET and callback URL"

get_next(){
    jq -r '.next' <<< "$*"
}

is_local_uri(){
    [[ "$1" =~ ^spotify:local:|open.spotify.com/local/ ]]
}

is_spotify_playlist_id(){
    #local playlist_id="${1:-}"
    #if [ -z "$playlist_id" ]; then
    #    die "no playlist id passed to function is_spotify_playlist_id()"
    #fi
    [[ "$1" =~ [[:alnum:]]{22} ]]
}

validate_spotify_uri(){
    local uri="$1"
    if ! [[ "$uri" =~ ^(spotify:(track|album|artist):|^https?://open.spotify.com/(track|album|artist)/)?[[:alnum:]]+(\?.+)?$ ]]; then
        echo "Invalid URI provided: $uri" >&2
        return 1
    fi
    if [[ "$uri" =~ open.spotify.com/|^spotify: ]]; then
        if ! [[ "$uri" =~ open.spotify.com/${uri_type:-track}|^spotify:${uri_type:-track} ]]; then
            echo "Invalid URI type '${uri_type:-track}' vs URI '$uri'" >&2
            return 1
        fi
    fi
    uri="${uri##*[:/]}"
    uri="${uri%%\?*}"
    echo "$uri"
}
