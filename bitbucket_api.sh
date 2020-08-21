#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 19:45:46 +0100 (Sun, 16 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

#  args: /user | jq .
#  args: /workspaces | jq .
#  args: /repositories/harisekhon | jq .
#  args: /repositories/harisekhon/devops-bash-tools/pipelines/ | jq .

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the BitBucket.org API

Can specify \$CURL_OPTS for options to pass to curl, or pass them as arguments to the script

Automatically handles authentication via environment variable \$BITBUCKER_USER and \$BITBUCKET_TOKEN
If either of these are not found, tries to infer from local git repo's bitbucket remotes


You must set up a personal access token here:

https://bitbucket.org/account/settings/app-passwords/


API Reference:

https://developer.atlassian.com/bitbucket/api/2/reference/
https://developer.atlassian.com/bitbucket/api/2/reference/resource/


Examples:


# Get currently authenticated user:

${0##*/} /user


# Get currently authenticated user's workspaces:

${0##*/} /workspaces


# Get repos in given workspace:

${0##*/} /repositories/harisekhon


# Get a repo's BitBucket Pipelines [oldest first] (must have a slash on the end otherwise gets 404 error):

${0##*/} /repositories/harisekhon/devops-bash-tools/pipelines/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.bitbucket.org/2.0"

CURL_OPTS="-sS --fail --connect-timeout 3 ${CURL_OPTS:-}"

help_usage "$@"

min_args 1 "$@"

user="${BITBUCKET_USER:-}"
PASSWORD="${BITBUCKET_PASSWORD:-${BITBUCKET_TOKEN:-${PASSWORD:-}}}"

if [ -z "${BITBUCKET_USER:-}" ]; then
    user="$(git remote -v 2>/dev/null | awk '/https:\/\/.+@bitbucket\.org/{print $2; exit}' | sed 's|https://||;s/@.*//;s/:.*//' || :)"
    # curl_auth.sh does this automatically
    #if [ -z "$user" ]; then
    #    user="${USERNAME:${USER:-}}"
    #fi
fi

if [ -z "${PASSWORD:-}" ]; then
    # if this is still blank then curl_auth.sh will detect and prompt for a password (non echo'd)
    PASSWORD="$(git remote -v 2>/dev/null | awk '/https:\/\/.+@bitbucket\.org/{print $2; exit}' | sed 's|https://||;s/@.*//;s/.*://' || :)"
fi

if [ -n "$user" ]; then
    export USER="$user"
fi
export PASSWORD

url_path="${1:-}"
url_path="${url_path##*:\/\/bitbucket.org\/api\/v4}"
url_path="${url_path##/}"

shift

repo=$(git_repo 2>/dev/null | sed 's/.*\///' || :)

url_path="${url_path/:owner/$USER}"
url_path="${url_path/:user/$USER}"
url_path="${url_path/:username/$USER}"
url_path="${url_path/<user>/$USER}"
url_path="${url_path/<username>/$USER}"
url_path="${url_path/:repo/$repo}"
url_path="${url_path/<repo>/$repo}"

# want splitting
# shellcheck disable=SC2086
#if is_curl_min_version 7.55; then
#    # this trick doesn't work, file descriptor is lost by next line
#    #filedescriptor=<(cat <<< "Private-Token: $BITBUCKET_TOKEN")
#    curl ${CURL_OPTS} -H @<(cat <<< "Private-Token: $BITBUCKET_TOKEN") "$url_base/$url_path" "$@"
#else
#    # could also use OAuth compliant header "Authorization: Bearer <token>"
#    curl ${CURL_OPTS:-} -H "Private-Token: $BITBUCKET_TOKEN" "$url_base/$url_path" "$@"
#fi

# need CURL_OPTS splitting, safer than eval
# shellcheck disable=SC2086
"$srcdir/curl_auth.sh" ${CURL_OPTS:-} "$url_base/$url_path" "$@"
