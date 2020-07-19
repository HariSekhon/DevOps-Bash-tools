#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-23 17:59:52 +0100 (Tue, 23 Jun 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns a Spotify access token from the Spotify API, needed to access the Spotify API

Due to quirks of the Spotify API, by default returns a non-interactive access token that cannot access private user data

To get a token to access the private user data API endpoints, set \$SPOTIFY_PRIVATE=1
This will then require a browser prompt to authorize, at which point this will capture and output the resulting token

Requires \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment

Generate an App client ID and secret here and add a callback URL of 'http://localhost:12345/callback':

https://developer.spotify.com/dashboard/applications
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

#if [ -n "${SPOTIFY_ACCESS_TOKEN:-}" ] &&
#   [ -n "${SPOTIFY_ACCESS_TOKEN//[[:space:]]}" ]; then
#    echo "$SPOTIFY_ACCESS_TOKEN"
#    exit 0
#fi

check_env_defined "SPOTIFY_ID"
check_env_defined "SPOTIFY_SECRET"

# encode spaces as %20 or +
scope="${SPOTIFY_TOKEN_SCOPE:-
app-remote-control
playlist-modify-private
playlist-modify-public
playlist-read-collaborative
playlist-read-private
streaming
user-follow-modify
user-follow-read
user-library-modify
user-library-read
user-modify-playback-state
user-read-currently-playing
user-read-email
user-read-playback-position
user-read-playback-state
user-read-private
user-read-recently-played
user-top-read
}
"
# perl -pe doesn't really work here, hard to remove leading/trailing ++ without slurp to real var
#scope="$(perl -e '$str = do { local $/; <STDIN> }; $str =~ s/\s+/\+/g; $str =~ s/^\++//; $str =~ s/\++$//; print $str' <<< "$scope")"
# simpler
scope="$(tr '\n' '+' <<< "$scope" | sed 's/^+//; s/+*$//')"

# ============================================================================ #
# Client Credentials method - the most suitable to scripting but doesn't grant access to user data :-/
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#client-credentials-flow
#
if [ -z "${SPOTIFY_PRIVATE:-}" ]; then
    output="$(curl -sSL -u "$SPOTIFY_ID:$SPOTIFY_SECRET" -X 'POST' -d 'grant_type=client_credentials' -d "scope=$scope" https://accounts.spotify.com/api/token "$@")"
fi

# ============================================================================ #

redirect_uri='http://localhost:12345/callback'

# ============================================================================ #
# Implicit Grant Method
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#implicit-grant-flow
#
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=token")"

# ============================================================================ #
# Authorization Code Flow with Proof Key for Code Exchange (PKCE)
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow-with-proof-key-for-code-exchange-pkce
#
#if [ "$(uname -s)" = Darwin ]; then
#    sha1sum(){
#        command shasum "$@"
#    }
#fi
#code_challenge="$("$srcdir/random_string.sh" 128 | sha1sum -a 256 | base64)"
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code&code_challenge_method=S256&code_challenge=$code_challenge")"

# ============================================================================ #
# Authorization Code Flow
#
# use spotify_api_token_interactive.sh for this method
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow
#
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code")"

if [ -n "${SPOTIFY_PRIVATE:-}" ]; then
    url="https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code"
    {
    if [ "$(uname -s)" = Darwin ]; then
        open "$url"
    else
        echo "Go to the following URL in your browser, authorize and then the token will be output on the command line:"
        echo
        echo "$url"
        echo
    fi

    log "waiting to catch callback"
    response="$(nc -l localhost 12345 <<EOF
HTTP/1.1 200 OK

OK, now return to command line
EOF
    )"
    log "callback caught"

    code="$(grep -Eo "GET.*code=([^?]+)" <<< "$response" | sed 's/.*code=//; s/[[:space:]].*$//' || :)"
    if [ -z "$code" ]; then
        echo "failed to parse code, authentication failure or authorization denied?"
        exit 1
    fi
    log "Parsed code: $code"
    log
    log "Requesting API token using code"

    # or send client_id + client_secret fields in POST body - using curl_auth.sh now to avoid this appearing in process list / logs
    #basic_auth_token="$(base64 <<< "$SPOTIFY_ID:$SPOTIFY_SECRET")"

    # output everything that isn't the token to stderr as it's almost certainly user information or errors and we don't want that to be captured by client scripts
    } >&2

    #curl -H "Authorization: Basic $basic_auth_token" -d grant_type=authorization_code -d code="$code" -d redirect_uri="$redirect_uri" https://accounts.spotify.com/api/token
    # won't appear in process list
    output="$(USERNAME="$SPOTIFY_ID" PASSWORD="$SPOTIFY_SECRET" "$srcdir/curl_auth.sh" -sSL -d grant_type=authorization_code -d code="$code" -d redirect_uri="$redirect_uri" https://accounts.spotify.com/api/token)"
fi

# shellcheck disable=SC2181
if [ $? != 0 ] || [[ "$output" =~ error_description ]]; then
    echo "$output" >&2
    exit 1
fi

jq -r '.access_token' <<< "$output"
