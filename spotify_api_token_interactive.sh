#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-07-18 19:03:41 +0100 (Sat, 18 Jul 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

# shellcheck disable=SC2034
usage_description="
Returns a Spotify access token with private user authorization from the interactive Spotify API (browser pop up)

Requires \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment

Generate an App client ID and secret here and add a callback URL of 'http://localhost:12345/callback':

https://developer.spotify.com/dashboard/applications

spotify_api_token.sh (adjacent) is better for most uses where user private data is not required as it's non-interactive
and therefore better for scripting without the human authorization prompt

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
scope="$(tr '\n' '+' <<< "$scope" | sed 's/^+//; s/+*$//')"

redirect_uri='http://localhost:12345/callback'

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

{
#curl -H "Authorization: Basic $basic_auth_token" -d grant_type=authorization_code -d code="$code" -d redirect_uri="$redirect_uri" https://accounts.spotify.com/api/token
# won't appear in process list
USERNAME="$SPOTIFY_ID" PASSWORD="$SPOTIFY_SECRET" "$srcdir/curl_auth.sh" -sSL -d grant_type=authorization_code -d code="$code" -d redirect_uri="$redirect_uri" https://accounts.spotify.com/api/token

} |
jq -r '.access_token'
