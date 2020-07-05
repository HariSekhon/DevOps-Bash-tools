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
Returns a Spotify access token from the Spotify API

Requires \$SPOTIFY_CLIENT_ID and \$SPOTIFY_CLIENT_SECRET to be defined in the environment

Generate an App client ID and secret here:

https://developer.spotify.com/dashboard/applications
"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

help_usage "$@"

check_env_defined "SPOTIFY_CLIENT_ID"
check_env_defined "SPOTIFY_CLIENT_SECRET"

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
output="$(curl -sSL -u "$SPOTIFY_CLIENT_ID:$SPOTIFY_CLIENT_SECRET" -X 'POST' -d 'grant_type=client_credentials' -d "scope=$scope" https://accounts.spotify.com/api/token "$@")"

# ============================================================================ #

# These next 3 methods won't never work because it relies on live Login challenge - only relevant to webapps

#redirect_uri="https:%2F%2Fgithub.com%2Fharisekhon"

# ============================================================================ #
# Authorization Code Flow
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#authorization-code-flow
#
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_CLIENT_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code")"

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
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_CLIENT_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=code&code_challenge_method=S256&code_challenge=$code_challenge")"

# ============================================================================ #
# Implicit Grant Method
#
#   https://developer.spotify.com/documentation/general/guides/authorization-guide/#implicit-grant-flow
#
#output="$(curl -sSL -X GET "https://accounts.spotify.com/authorize?client_id=$SPOTIFY_CLIENT_ID&redirect_uri=$redirect_uri&scope=$scope&response_type=token")"

# shellcheck disable=SC2181
if [ $? != 0 ] || [[ "$output" =~ error_description ]]; then
    echo "$output" >&2
    exit 1
fi

jq -r '.access_token' <<< "$output"
