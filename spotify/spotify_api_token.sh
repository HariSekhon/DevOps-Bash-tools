#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-23 17:59:52 +0100 (Tue, 23 Jun 2020)
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

# shellcheck disable=SC2034
usage_description="
Returns a Spotify access token from the Spotify API, using app credentials. This token is needed to access the rest of the Spotify API endpoints

Requires \$SPOTIFY_ID and \$SPOTIFY_SECRET to be defined in the environment

Due to quirks of the Spotify API, by default returns a non-interactive access token that cannot access private user data

To get a token to access the private user data API endpoints:

export SPOTIFY_PRIVATE=1

This will then require an interactive browser pop-up prompt to authorize, at which point this script will capture and output the resulting token

Many scripts utilize this code and will automatically generate the authentication tokens for you if you have \$SPOTIFY_ID and \$SPOTIFY_SECRET environment variables set so you usually don't need to call this yourself


For private tokens which require authorization pop-ups, if you want to avoid these on every run of these spotify scripts, you can preload a private authorized token in to your shell for an hour like so:

export SPOTIFY_ACCESS_TOKEN=\"\$(SPOTIFY_PRIVATE=1 '$srcdir/../spotify/spotify_api_token.sh')


Generate an App client ID and secret for SPOTIFY_ID and SPOTIFY_SECRET environment variables here:

https://developer.spotify.com/dashboard/applications

Make sure to add a callback URL of exactly 'http://localhost:12345/callback' without the quotes to be able to generate private tokens
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<curl_options>]"

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
if is_blank "${SPOTIFY_PRIVATE:-}"; then
    output="$(NO_TOKEN_AUTH=1 USERNAME="$SPOTIFY_ID" PASSWORD="$SPOTIFY_SECRET" "$srcdir/../bin/curl_auth.sh" -sSL -X 'POST' -d 'grant_type=client_credentials' -d "scope=$scope" https://accounts.spotify.com/api/token "$@")"
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
#code_challenge="$("$srcdir/../bin/random_string.sh" 128 | sha1sum -a 256 | base64)"
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code&code_challenge_method=S256&code_challenge=$code_challenge")"

# ============================================================================ #
# Authorization Code Flow
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow
#
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code")"

callback_port=12345

callback(){
    {
    log "waiting to catch callback"
    local timestamp
    timestamp="$(date '+%F %T')"
    local netcat_switches
    netcat_switches="-l localhost 12345"
    # GNU netcat has different switches :-/
    # also errors out so we have to ignore its error code
    if nc --version 2>&1 | grep -q GNU; then
        netcat_switches="-l -p $callback_port --close"
    fi
    #local response
    # need opt splitting
    # shellcheck disable=SC2086
    response="$(nc $netcat_switches <<EOF || :
HTTP/1.1 200 OK

$timestamp  Spotify token accepted, now return to command line to use Spotify API tools
EOF
    )"
    log "callback caught"

    local code
    code="$(grep -Eo "GET.*code=([^?]+)" <<< "$response" | sed 's/.*code=//; s/[&[:space:]].*$//' || :)"
    if is_blank "$code"; then
        echo "failed to parse code, authentication failure or authorization denied?"
        exit 1
    fi
    log "Parsed code: $code"
    log
    log "Requesting API token using code"

    # or send client_id + client_secret fields in POST body - using curl_auth.sh now to avoid this appearing in process list / logs
    #basic_auth_token="$(base64 <<< "$SPOTIFY_ID:$SPOTIFY_SECRET")"

    #curl -H "Authorization: Basic $basic_auth_token" -d grant_type=authorization_code -d code="$code" -d redirect_uri="$redirect_uri" https://accounts.spotify.com/api/token
    # curl_auth.sh prevents auth token appearing in process list
    local output
    output="$(NO_TOKEN_AUTH=1 USERNAME="$SPOTIFY_ID" PASSWORD="$SPOTIFY_SECRET" "$srcdir/../bin/curl_auth.sh" https://accounts.spotify.com/api/token -sSL -d grant_type=authorization_code -d code="$code" -d redirect_uri="$redirect_uri")"

    # output everything that isn't the token to stderr as it's almost certainly user information or errors and we don't want that to be captured by client scripts
    } >&2
    echo "$output"
}

# Authorization Code Flow
if not_blank "${SPOTIFY_PRIVATE:-}"; then
    # clean up subprocesses to prevent netcat from being left behind as an orphan and blocking future runs
    # shellcheck disable=SC2064
    trap "kill -- -$$" EXIT
    callback | jq -r '.access_token' &
    sleep 1
    if ! pgrep -q -P $$; then
        die "Callback exited prematurely, port $callback_port may have been already bound, not launching authorization to prevent possible credential interception"
    fi
    trap -- EXIT
    {
    # authorization code flow
    url="https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code"
    # implicit grant flow would use response_type=token, but this requires an SSL connection in the redirect URI and would complicate things with localhost SSL server certificate management
    if is_mac; then
        frontmost_process="$("$srcdir/applescript/get_frontmost_process.scpt")"
        open "$url"
        "$srcdir/applescript/browser_close_tab.scpt"
        "$srcdir/applescript/set_frontmost_process.scpt" "$frontmost_process"
    else
        echo "Go to the following URL in your browser, authorize and then the token will be output on the command line:"
        echo
        echo "$url"
        echo
    fi
    } >&2
    wait
else
    #die_if_error_field "$output"
    jq -r '.access_token' <<< "$output"
fi
