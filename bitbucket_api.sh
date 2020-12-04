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
#  args: /repositories/harisekhon/devops-bash-tools -X PUT -H 'Content-Type: application/json' -d '{"description": "some words"}'

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the BitBucket.org API (v2.0)

Can specify \$CURL_OPTS for options to pass to curl, or pass them as arguments to the script

Automatically handles authentication via environment variables \$BITBUCKET_USERNAME / \$BITBUCKER_USER and \$BITBUCKET_TOKEN (which is used as the password, your real BitBucket password isn't accepted by the BitBucket 2.0 API)
If either of these are not found, tries to infer from local git repo's bitbucket remotes

You must set up a personal access token here:

https://bitbucket.org/account/settings/app-passwords/


API Reference:

https://developer.atlassian.com/bitbucket/api/2/reference/
https://developer.atlassian.com/bitbucket/api/2/reference/resource/


Examples:


# Get currently authenticated user's workspaces:

    ${0##*/} /workspaces | jq .


# Get repos in given workspace:

    ${0##*/} /repositories/harisekhon | jq .


# Get a repo's BitBucket Pipelines [oldest first] (must have a slash on the end otherwise gets 404 error):

    ${0##*/} /repositories/harisekhon/devops-bash-tools/pipelines/ | jq .


# Update a repo's description:

    ${0##*/} /repositories/harisekhon/devops-bash-tools -X PUT -H 'Content-Type: application/json' -d '{\"description\": \"some words\"}' | jq .


# Get currently authenticated user (unfortunately this is less useful than with GitHub / GitLab APIs since you can't use a standard OAuth2 authentication with just the bearer token, and must specify a username to authenticate to the API in the first place):

    ${0##*/} /user | jq .


For convenience you can even copy and paste out of the documentation literally and have the script auto-determine the right settings.

Placeholders are replaced if the following information is available in environment variables or can be inferred from the local git repo remote urls. The tokens for replacement can be given in the form {token}, <token>, :token

\$BITBUCKET_USERNAME / \$BITBUCKET_USER:             owner, username, user
the local repo name of the current directory:      repo
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.bitbucket.org/2.0"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

user="${BITBUCKET_USERNAME:-${BITBUCKET_USER:-}}"
PASSWORD="${BITBUCKET_PASSWORD:-${BITBUCKET_TOKEN:-}}"

if [ -z "$user" ]; then
    echo "WARNING: \$BITBUCKET_USERNAME / \$BITBUCKET_USER not specified, attempting to determine from local remote url" >&2
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
    export USERNAME="$user"
else
    echo "WARNING: \$BITBUCKET_USERNAME / \$BITBUCKET_USER not specified, and failed to determine from local remote url, will end up using your environment's default \$USERNAME / \$USER which may not be the right BitBucket username and can lead to authentication failures - recommend you set \$BITBUCKET_USERNAME explicitly" >&2
fi
export PASSWORD

url_path="${1:-}"
url_path="${url_path##*:\/\/bitbucket.org\/api\/v4}"
url_path="${url_path##/}"

shift

repo=$(git_repo 2>/dev/null | sed 's/.*\///' || :)

if [ -n "$user" ]; then
    url_path="${url_path/\{username\}/$user}"
    url_path="${url_path/<username>/$user}"
    url_path="${url_path/:username/$user}"
    url_path="${url_path/\{user\}/$user}"
    url_path="${url_path/<user>/$user}"
    url_path="${url_path/:user/$user}"
fi
url_path="${url_path/\{repo\}/$repo}"
url_path="${url_path/<repo>/$repo}"
url_path="${url_path/:repo/$repo}"

"$srcdir/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
