#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: pylib
#
#  Author: Hari Sekhon
#  Date: 2023-06-03 00:02:53 +0100 (Sat, 03 Jun 2023)
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
. "$srcdir/lib/bitbucket.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Disable the CI/CD pipeline for a given BitBucket.org repo via the BitBucket API

Uses the adjacent script bitbucket_api.sh, see there for authentication details

\$CURL_OPTS can be set to provide extra arguments to curl


Repo should be specified as <workspace>/<repo> using the slugs which are usually just the same as the username and repo lowercase (they're case sensitive, eg. harisekhon/devops-bash-tools)

Repo workspace prefix, if not set, is assumed to be the username and will use \$BITBUCKET_USER if available, otherwise will query the BitBucket API to determine it


If you get an error it's possible you don't have the right token permissions.
You can generate a new token with the right permissions here:

    https://bitbucket.org/account/settings/app-passwords/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<repo>"

help_usage "$@"

num_args 1 "$@"

repo="$1"

if ! [[ "$repo" =~ / ]]; then
    log "No username prefix in repo '$repo', will auto-add it"
    # refuse bitbucket_user between function calls for efficiency to save additional queries to the BitBucket API
    if [ -z "${bitbucket_user:-}" ]; then
        bitbucket_user="$(get_bitbucket_user)"
    fi
    repo="$bitbucket_user/$repo"
fi

timestamp "Disabling pipeline for BitBucket repo '$repo'"

"$srcdir/bitbucket_api.sh" "/repositories/$repo/pipelines_config" -X PUT -H 'Content-Type: application/json' --data '{ "enabled": false }' >/dev/null
