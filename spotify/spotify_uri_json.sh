#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  args: https://open.spotify.com/track/2aq9tUKdAy8kOXhpGtWBfp
#
#  Author: Hari Sekhon
#  Date: 2026-02-11 00:16:53 -0300 (Wed, 11 Feb 2026)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/spotify.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Takes a Spotify URI and dumps its JSON for inspection

You can pass one of the following formats:

spotify:<type>:<alphanumeric_ID>

http://open.spotify.com/<type>/<alphanumeric_ID>

<alphanumeric_ID>


where <type> is track / episode / album / artist

These IDs are 22 chars, but this is length is not enforced in case the Spotify API changes


$usage_auth_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<spotify_uri> [<curl_options>]"

help_usage "$@"

uri="${1:-}"
shift || :

spotify_token

infer_uri_type(){
    local uri="$1"

    if [[ "$uri" =~ ^spotify:(track|album|artist|episode): ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$uri" =~ ^https?://open.spotify.com/(track|album|artist|episode)/ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        # fallback
        echo "${SPOTIFY_URI_TYPE:-track}"
    fi
}

type="$(infer_uri_type "$uri")"

id="$(validate_spotify_uri "$uri")"

url="/v1/${type}s/$id"

output="$("$srcdir/spotify_api.sh" "$url" "$@")"

jq . <<< "$output"
