#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /repos
#  args: /user
#
#  Author: Hari Sekhon
#  Date: 2020-09-17 18:35:11 +0100 (Thu, 17 Sep 2020)
#
#  https://travis.com/harisekhon/bash-tools
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

# shellcheck disable=SC1090,SC1091
#. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Travis CI API v3 for travis-ci.org (open source site)

Modify url_base from travis-ci.org to travis-ci.com if you need to use this on the pro site

Requires \$TRAVIS_TOKEN to be available in the environment

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Get an API access token here:

    https://travis-ci.org/account/preferences

or call 'travis token' using the CLI gem as documented here:

    https://developer.travis-ci.org/authentication


API Reference:

    https://developer.travis-ci.com/


See Also:

    https://developer.travis-ci.org/explore/


Examples:


# Get the currently authenticated user:

    ${0##*/} /user


# Get Organizations the current user has access to:

    ${0##*/} /orgs


# Get Repositories:

    ${0##*/} /repos


# Get builds:

    ${0##*/} /builds


# Get crons (repository slug must be url-encoded replacing slash with %2F):

    ${0##*/} /repo/<user>%2F<repo>/crons

    ${0##*/} /repo/HariSekhon%2FDevOps-Bash-tools/crons


# Get jobs:

    ${0##*/} /jobs


# Get repository settings:

    ${0##*/} /repo/<user>%2F<repo>/settings

    ${0##*/} /repo/HariSekhon%2FDevOps-Bash-tools/settings


# List caches for a repository:

    ${0##*/} /repo/<user>%2F<repo>/caches

    ${0##*/} /repo/HariSekhon%2FDevOps-Bash-tools/caches


# List environment variables for a repository:

    ${0##*/} /repo/<user>%2F<repo>/env_vars

    ${0##*/} /repo/HariSekhon%2FDevOps-Bash-tools/env_vars
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.travis-ci.org"

help_usage "$@"

min_args 1 "$@"

check_env_defined TRAVIS_TOKEN

export TOKEN="$TRAVIS_TOKEN"

curl_api_opts "$@"

url_path="${1:-}"
shift || :

url_path="${url_path//https:\/\/api.travis-ci.org}"
url_path="${url_path##/}"

export CURL_AUTH_HEADER="Authorization: token"

"$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" -H 'Travis-API-Version: 3' "${CURL_OPTS[@]}" "$@"
