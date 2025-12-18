#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-12-18 14:25:17 -0600 (Thu, 18 Dec 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries for a search string, returns the first hit and then generates a stable fixed place ID url to the result

Useful for sharing in documentation links to places like HariSekhon/Knowledge-Base Travel pages

A Google Maps API Key is required otherwise you will get an error like this:

	{
	   \"error_message\" : \"You must use an API key to authenticate each request to Google Maps Platform APIs. For additional information, please refer to http://g.co/dev/maps-no-account\",
	   \"html_attributions\" : [],
	   \"results\" : [],
	   \"status\" : \"REQUEST_DENIED\"
	}

or this if you haven't enabled billing or your payment method has expired, causing the billing account to be disabled:

	{
	  \"error_message\": \"You must enable Billing on the Google Cloud Project at https://console.cloud.google.com/project/_/billing/enable Learn more at https://developers.google.com/maps/gmp-get-started\",
	  \"html_attributions\": [],
	  \"results\": [],
	  \"status\": \"REQUEST_DENIED\"
	}

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<query>"

help_usage "$@"

min_args 1 "$@"

query="$*"

check_env_defined GOOGLE_MAPS_API_KEY

encoded_query="$(
    printf '%s' "$query" |
    jq -sRr @uri
)"

place_id="$(
    curl -s \
        "https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encoded_query}&key=${GOOGLE_MAPS_API_KEY}" |
    jq_debug_pipe_dump |
    jq -r '.results[0].place_id // empty'
)"

if [ -z "$place_id" ]; then
    echo "No place ID found" >&2
    exit 1
fi

printf 'https://www.google.com/maps/place/?q=place_id:%s\n' "$place_id"
