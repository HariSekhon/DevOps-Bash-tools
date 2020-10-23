#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-23 17:58:16 +0100 (Fri, 23 Oct 2020)
#
#  https://azure_devops.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the Azure DevOps API

Automatically handles authentication via environment variables \$AZURE_DEVOPS_USERNAME / \$AZURE_DEVOPS_USER
and \$AZURE_DEVOPS_TOKEN / \$AZURE_DEVOPS_PASSWORD

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here:

https://dev.azure.com/\$AZURE_DEVOPS_USER/_usersSettings/tokens


API Reference:

https://docs.microsoft.com/en-us/rest/api/azure/devops/


Examples:


# List a user's Azure DevOps repos:

    ${0##*/} /{organization}/{project}/_apis/git/repositories  | jq .

# List a user's Azure DevOps Pipelines:

    ${0##*/} /{username}/{project}/_apis/pipelines | jq .


For convenience the following tokens in the form :token, <token>, {token} are replaced:

Placeholders replaced by \$AZURE_DEVOPS_USERNAME / \$AZURE_DEVOPS_USER:     organization, owner, username, user
Placeholders replaced by the local repo name of the current directory:    repo
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://dev.azure.com"

CURL_OPTS="-sS --fail --connect-timeout 3 ${CURL_OPTS:-}"

help_usage "$@"

min_args 1 "$@"

user="${AZURE_DEVOPS_USERNAME:-${AZURE_DEVOPS_USER:-}}"
if [ -z "$user" ]; then
    user="$(git remote -v 2>/dev/null | awk '/https:\/\/.+@dev\.azure\.com/{print $2; exit}' | sed 's|https://||;s/@.*//;s/:.*//' || :)"
    # curl_auth.sh does this automatically
    #if [ -z "$user" ]; then
    #    user="${USERNAME:${USER:-}}"
    #fi
fi

project="${AZURE_DEVOPS_PROJECT:-}"
if [ -z "$project" ]; then
    project="$(git remote -v 2>/dev/null | awk '/https:\/\/.+@dev\.azure\.com/{print $2; exit}' | sed 's/.*dev.azure.com\(:v3\)*\/[^/]*\///; s/\/.*$//' || :)"
    # curl_auth.sh does this automatically
    #if [ -z "$user" ]; then
    #    user="${USERNAME:${USER:-}}"
    #fi
fi

PASSWORD="${AZURE_DEVOPS_PASSWORD:-${AZURE_DEVOPS_TOKEN:-}}"

if [ -z "${PASSWORD:-}" ]; then
    PASSWORD="$(git remote -v | awk '/https:\/\/[[:alnum:]]+@azure_devops\.com/{print $2; exit}' | sed 's|https://||;s/@.*//')"
fi

if [ -n "$user" ]; then
    export USERNAME="$user"
fi
export PASSWORD

#if [ -n "${PASSWORD:-}" ]; then
#    echo "using authenticated access" >&2
#fi

url_path="${1:-}"
shift

url_path="${url_path//$url_base}"
url_path="${url_path##/}"

# for convenience of straight copying and pasting out of documentation pages

repo=$(git_repo | sed 's/.*\///')

if [ -n "$user" ]; then
    url_path="${url_path/:organization/$user}"
    url_path="${url_path/<organization>/$user}"
    url_path="${url_path/\{organization\}/$user}"
    url_path="${url_path/:owner/$user}"
    url_path="${url_path/<owner>/$user}"
    url_path="${url_path/\{owner\}/$user}"
    url_path="${url_path/:username/$user}"
    url_path="${url_path/<username>/$user}"
    url_path="${url_path/\{username\}/$user}"
    url_path="${url_path/:user/$user}"
    url_path="${url_path/<user>/$user}"
    url_path="${url_path/\{user\}/$user}"
fi
if [ -n "$project" ]; then
    url_path="${url_path/:project/$project}"
    url_path="${url_path/<project>/$project}"
    url_path="${url_path/\{project\}/$project}"
fi
url_path="${url_path/:repo/$repo}"
url_path="${url_path/<repo>/$repo}"
url_path="${url_path/\{repo\}/$repo}"

# need CURL_OPTS splitting, safer than eval
# shellcheck disable=SC2086
"$srcdir/curl_auth.sh" "$url_base/$url_path" "$@" $CURL_OPTS
