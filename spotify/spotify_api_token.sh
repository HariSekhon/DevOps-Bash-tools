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

Make sure to add a callback URL of exactly 'http://127.0.0.1:12345/callback' without the quotes to be able to generate private tokens
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

# If we only need a public access token we do this simpler workflow call and exit after printing the token

if is_blank "${SPOTIFY_PRIVATE:-}"; then
    output="$(
        NO_TOKEN_AUTH=1 \
        USERNAME="$SPOTIFY_ID" \
        PASSWORD="$SPOTIFY_SECRET" \
        "$srcdir/../bin/curl_auth.sh" \
        -sSL \
        -X 'POST' \
        -d 'grant_type=client_credentials' \
        -d "scope=$scope" \
        https://accounts.spotify.com/api/token \
        "$@"
    )"
    #die_if_error_field "$output"
    jq -r '.access_token' <<< "$output"
    exit "$?"
fi

# ============================================================================ #
# Callback for Private authz catch

callback_port=12345

redirect_uri="http://127.0.0.1:$callback_port/callback"
redirect_uri_encoded="$(printf '%s' "$redirect_uri" | jq -s -R -r @uri)"

# Spotify not respecting the localhost cert anyway since it doesn't get that far on the redirect with the following error:
#
#   INVALID_CLIENT: Insecure redirect URI
#
# Must use loopback with http anyway

#callback_key="$(mktemp /tmp/spotify_callback.key.XXXXXXXXXX)"
#callback_crt="$(mktemp /tmp/spotify_callback.crt.XXXXXXXXXX)"

##callback_key="$srcdir/spotify_callback.key"
#callback_key="$srcdir/localhost-key.pem"
##callback_crt="$srcdir/spotify_callback.crt"
#callback_crt="$srcdir/localhost.pem"
#callback_p12="$srcdir/localhost.p12"
##callback_cnf="$srcdir/spotify_callback_openssl.cnf"
#callback_p12_password="spotify"
#
## generate self-signed certificate if it doesn't already exist
#if ! [ -f "$callback_key" ] ||
#   ! [ -f "$callback_crt" ]; then
#    timestamp "Creating a spotify callback OpenSSL certificate"
##    openssl=openssl
#    if is_mac; then
#        MAC=1
#        openssl="$(brew --prefix openssl)/bin/openssl"
#    fi
##    openssl version -a
##    #"$openssl" req -newkey rsa:2048 -nodes \
##    #               -keyout "$callback_key" \
##    #               -x509 -days 3650 \
##    #               -out "$callback_crt" \
##    #               -subj "/CN=localhost" 2>/dev/null
##    "$openssl" req -x509 -nodes -days 3650 \
##                   -newkey rsa:2048 \
##                   -keyout "$callback_key" \
##                   -out "$callback_crt" \
##                   -config "$callback_cnf" \
##                   2>/dev/null
#    mkcert -install
#    mkcert localhost  # this overwrites existing localhost.pem and localhost-key.pem
#    timestamp "Creating a p12 certificate bundle to import into keychain"
#    "$openssl" pkcs12 -export \
#                      -name spotify_callback \
#                      ${MAC:+-legacy -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1} \
#                      -inkey "$callback_key" \
#                      -in "$callback_crt" \
#                      -out "$callback_p12" \
#                      -passout pass:"$callback_p12_password"
#                      # do not use these switches - tried with libressl but macOS keychain refuses to import
#                      #-nomac \
#                      #-keypbe NONE \
#                      #-certpbe NONE
#    #timestamp "Checking the p12 isn't encrypted" # actually needed to be encrypted to be accepted into the keychain
#    # Expected lines: "MAC: sha256, ..." and "Key bag" (NOT "Shrouded Keybag" and NOT "Warning: MAC is absent!")
#    #"$openssl" pkcs12 -in "$callback_p12" -noout -info -passin pass:"$callback_p12_password"
#    if is_mac; then
#        # macOS won't trust the local root cert without the key, so must generate and import the p12
#        timestamp "Importing p12 into keychain: $callback_p12"
#        sudo security import "$callback_p12" \
#                             -k /Library/Keychains/System.keychain \
#                             -P "$callback_p12_password" \
#                             -A
#        timestamp "Importing cert into keychain: $callback_crt"
#        sudo security add-trusted-cert \
#                        -d \
#                        -r trustRoot \
#                        -k /Library/Keychains/System.keychain \
#                        "$callback_crt"
#        timestamp "Verifying cert is trusted: $callback_crt"
#        security verify-cert -c "$callback_crt"
#    else
#        warn "you must import this certificate to be trusted by your browser: $callback_crt"
#    fi
#fi

callback(){
    {
    log "Waiting to catch callback"
    local timestamp
    timestamp="$(date '+%F %T')"
    local netcat_switches
    netcat_switches="-l localhost $callback_port"
    # GNU netcat has different switches :-/
    # also errors out so we have to ignore its error code
    if nc --version 2>&1 | grep -q GNU; then
        netcat_switches="-l -p $callback_port --close"
    fi
    # TODO: add a mutex wait lock here, UPDATE: can't remember why I wrote this now, there is a wait at the end for this
    pkill -9 -f "^nc $netcat_switches$" || :
    trap_cmd "pkill -9 -f '^nc $netcat_switches$'"
    #trap_cmd "pkill -9 -f '^openssl s_server .* -accept $callback_port'"
    #log "Killing any existing openssl listener if there is already one running on port: $callback_port"
    #pkill -9 -f "^openssl s_server .* -accept $callback_port" || :
    sleep 1
    #local response
    # need opt splitting
    # shellcheck disable=SC2086
    #response="$(openssl s_server \
    #                -quiet \
    #                -key "$callback_key" \
    #                -cert "$callback_crt" \
    #                -accept 12345 \
    #                -www 2>/dev/null <<EOF || :
    response="$(nc $netcat_switches <<EOF || :
HTTP/1.1 200 OK

$timestamp  Spotify token accepted, now return to command line to use Spotify API tools
EOF
    )"
    log "Callback Caught"

    local code
    log "Response: $response"
    log
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
    # debugging
    #printf 'DEBUG raw redirect_uri=<%s>\n' "$redirect_uri" >&2
    output="$(
        NO_TOKEN_AUTH=1 \
        USERNAME="$SPOTIFY_ID" \
        PASSWORD="$SPOTIFY_SECRET" \
        "$srcdir/../bin/curl_auth.sh" \
        https://accounts.spotify.com/api/token \
        -sSL \
        -d grant_type=authorization_code \
        -d redirect_uri="$redirect_uri" \
        -d code="$code" \
        #-d code_verifier="$code_verifier"
    )"

    # output everything that isn't the token to stderr as it's almost certainly user information or errors and we don't want that to be captured by client scripts
    } >&2
    echo "$output"
}

# ============================================================================ #
# Implicit Grant Method
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#implicit-grant-flow
#
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=token")"

# ============================================================================ #
# Authorization Code Flow
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow
#
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code")"

# ============================================================================ #
# Authorization Code Flow with Proof Key for Code Exchange (PKCE)
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow-with-proof-key-for-code-exchange-pkce

#code_verifier="$(
#    head -c 64 /dev/urandom |
#    base64 |
#    tr '+/' '-_' |
#    tr -d '='
#)"
#
#code_challenge=$(
#    printf '%s' "$code_verifier" |
#    openssl dgst -sha256 -binary |
#    base64 |
#    tr '+/' '-_' |
#    tr -d '=' |
#    tr -d '\n' |
#    tr -d '[:space:]'
#)
#
#if [ "$(uname -s)" = Darwin ]; then
#    sha1sum(){
#        command shasum "$@"
#    }
#fi

# ============================================================================ #
# using Authorization Code Flow

applescript="$srcdir/../applescript"

# Authorization Code Flow with PKCE
if not_blank "${SPOTIFY_PRIVATE:-}"; then
    # clean up subprocesses to prevent netcat from being left behind as an orphan and blocking future runs
    # shellcheck disable=SC2064
    trap "kill -- -$$" EXIT
    callback |
    tee /dev/stderr |
    jq -r '.access_token' &
    sleep 1
    if ! pgrep -q -P $$; then
        die "Callback exited prematurely, port $callback_port may have been already bound, not launching authorization to prevent possible credential interception"
    fi
    trap -- EXIT
    {
    url="https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri_encoded&scope=$scope&response_type=code"
    # authorization code flow with PKCE
    #url="https://accounts.spotify.com/authorize?client_id=$SPOTIFY_ID&redirect_uri=$redirect_uri_encoded&scope=$scope&response_type=code&code_challenge_method=S256&code_challenge=$code_challenge"
    # implicit grant flow would use response_type=token, but this requires an SSL connection in the redirect URI and would complicate things with localhost SSL server certificate management
    if is_mac; then
        log "URL: $url"
        frontmost_process="$("$applescript/get_frontmost_process.scpt")"
        "$srcdir/../bin/urlopen.sh" "$url"
        # if using PKCE, need to add code to save and reuse refresh_token, otherwise it results in a fresh authorization page each time
        # send Tab, Tab, Tab, Space to accept the new prompt page
        #START_DELAY=1 SLEEP_SECS=1 "$srcdir/../applescript/keystrokes.sh" 1 48 48 48 49
        # don't close the tab too fast or the token isn't passed to the local callback handler
        sleep 0.5
        "$applescript/browser_close_tab.scpt"
        "$applescript/set_frontmost_process.scpt" "$frontmost_process"
    else
        echo
        echo "Go to the following URL in your browser, authorize and then the token will be output on the command line:"
        echo
        echo "$url"
        echo
        "$srcdir/../bin/urlopen.sh" "$url"
        echo
    fi
    } >&2
    wait
fi
