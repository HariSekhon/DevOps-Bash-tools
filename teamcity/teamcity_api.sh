#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-27 16:38:30 +0100 (Thu, 27 Aug 2020)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Teamcity API

Requires \$TEAMCITY_TOKEN be available in the environment, generation a token here:

    \$TEAMCITY_URL/profile.html?item=accessTokens
        or
    https://\$TEAMCITY_HOST:\$TEAMCITY_PORT/profile.html?item=accessTokens

If using the superuser token, it must instead be specified as \$TEAMCITY_SUPERUSER_TOKEN and takes precedence


\$TEAMCITY_URL or \$TEAMCITY_HOST must be set to point to the Teamcity server

If \$TEAMCITY_HOST is used, then the following may also be set:

\$TEAMCITY_PORT - defaults to 8111 and is only used if \$TEAMCITY_URL is not used
\$TEAMCITY_SSL  - defaults to http, any value enables https

If no Accept or Content-Type headers are passed in the arguments, then sets them to application/json by default because the API returns XML otherwise, and who wants that in the modern age... but this still allows you to override them for the odd endpoint that requires instead sending text/plain (looking at you Agent authorization endpoint)


API Reference:

    https://www.jetbrains.com/help/teamcity/rest-api.html

    https://www.jetbrains.com/help/teamcity/rest-api-reference.html


The API version used by default is latest, but you can specify an older API version like so:

\$TEAMCITY_API_VERSION=2018.1

At time of writing, prior API versions are: 2018.1, 2017.2, 2017.1, 10.0, 9.1, 9.0, 8.1, 8.0. See:

    https://www.jetbrains.com/help/teamcity/rest-api.html#REST+API+Versions


See Also:

    teamcity.sh - boots a TeamCity cluster in Docker and makes heavy use of this script against many API endpoints to configure it
                  convenient way of getting a TeamCity API to test this script against, outputs the TEAMCITY_URL and TEAMCITY_TOKEN for you

    teamcity_builds.sh - lists builds using this API
    teamcity_agents.sh - lists agents using this API


Examples:

(don't forget to add '\$help' to the end to find out what attributes endpoints support):
Remember you can check logs/teamcity-rest.log server log for these API requests



# Explore API:

    ${0##*/} /server


# Explore supported requests and parameters:

    ${0##*/} /application.wadl


# Swagger endpoint:

    ${0##*/} /swagger.json


# Show Teamcity agents:

    ${0##*/} /agents


# Get an agent's details:

    ${0##*/} /agents/id:3


# Get list of builds:

    ${0##*/} /builds


# Get list of builds filtered by successful status with a specific tag:

    ${0##*/} /builds?locator=status:SUCCESS,tag=dev


# Get the build queue:

    ${0##*/} /buildQueue


# Get list of projects:

    ${0##*/} /projects


# Get details on a specific project:

    ${0##*/} /projects/<id>
# or
    ${0##*/} /projects/id:<id>


# Get list of revision control repositories roots:

    ${0##*/} /vcs-roots


# Get details on one specific revision control repository:

    ${0##*/} /vcs-roots/id:<id>


# Get list of cloud profiles (kubernetes is configured here):

    ${0##*/} /cloud/profiles


# Check your license details:

    ${0##*/} /server/licensingData
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

url_path="$1"
shift || :

url_path="${url_path##/}"

curl_api_opts "$@"

# don't enforce as hard requirements here, instead try alternation further down and construct from what's available
#check_env_defined "TEAMCITY_URL"
#check_env_defined "TEAMCITY_HOST"
#check_env_defined "TEAMCITY_TOKEN"

# to speed up http basic auth:
#
# https://youtrack.jetbrains.com/issue/TW-14209
#
# https://youtrack.jetbrains.com/issue/TW-36844#comment=27-752545
#
# used to put this in /tmp but it is created world readable by default and when securing it there is a race condition
# between the 2 curl and chmod lines, whereas $HOME is more likely to be read restricted
# now additionally this is initialized with restricted permissions before it is ever used to avoid this race condition
cookie_jar=~/".teamcity_cookie_jar/.${EUID:-$UID}.$$"
mkdir -p "${cookie_jar%/*}"  # pre-create the directory
# XXX: this cookie jar causes 403 to API endpoints such as /agents/id:1/authorized when switching between -H 'Accept: application/json' and -H 'Accept: text/plain' as that endpoint only works with the latter but this cache breaks this
#rm -f "$cookie_jar"
#touch "$cookie_jar"
: > "$cookie_jar"
chown "$(whoami)" "$cookie_jar"
chmod 0600 "$cookie_jar"

CURL_OPTS+=(-b "$cookie_jar" -c "$cookie_jar")

if [ -n "${TEAMCITY_URL:-}" ]; then
    url_base="${TEAMCITY_URL%%/}"
else
    protocol="http"
    if [ -n "${TEAMCITY_SSL:-}" ]; then
        protocol="https"
    fi
    [ -n "${TEAMCITY_HOST:-}" ] || usage "neither \$TEAMCITY_URL nor \$TEAMCITY_HOST defined in environment"
    host="$TEAMCITY_HOST"
    port="${TEAMCITY_PORT:-8111}"
    url_base="$protocol://$host:$port"
fi

# for superuser account, empty username and system generated password, but curl_auth.sh won't allow that so handle it separately via $TEAMCITY_SUPERUSER_TOKEN further down
if [ -n "${TEAMCITY_TOKEN:-}" ]; then
    export TOKEN="$TEAMCITY_TOKEN"
else
    # XXX: might have to disable this is configuring CORS, see here:
    #
    # https://www.jetbrains.com/help/teamcity/rest-api.html#CORS-support
    #
    # for HTTP basic auth, set this to force it
    url_base+="/httpAuth"
fi

url_base+="/app/rest"

# fix to a specific API version, but teamcity only supports one legacy API version so this is more likely to break things over time :-/  (currently 2018.1)
if [ -n "${TEAMCITY_API_VERSION:-}" ]; then
    #url_base+="/2018.1"
    url_base+="/${TEAMCITY_API_VERSION##/}"
fi

# use superuser token override to support teamcity.sh when token has already been created but we cannot get it's key value out of the API, so need to continue using superuser token
if [ -n "${TEAMCITY_SUPERUSER_TOKEN:-}" ]; then
    # XXX: superuser token can only be used with blank user which cannot be used with curl_auth.sh
    curl -u ":$TEAMCITY_SUPERUSER_TOKEN" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
else
    "$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
fi
#chmod 0600 "$cookie_jar"

# args: /swagger.json | jq .
# args: /server | jq .  # get all the API details, takes a moment to query
# args: /projects | jq .
# args: /users | jq .  # you might get a 403 Forbidden
# args: /application.wadl | jq .  # 406
# args: /agents | jq .
# args: /agents/id:10 | jq.
# args: /builds | jq .
# args: /builds?locator=status:SUCCESS,tag=dev | jq .
# args: /vcs-roots | jq .
# run: teamcity_api.sh /vcs-roots | jq -r '."vcs-root"[].id' | while read -r id; do teamcity_api.sh "/vcs-roots/id:$id"; break; done | jq .
# args: /cloud/profiles
