#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: /user | jq .
#  args: /users/HariSekhon/repos | jq .
#  args: /repos/HariSekhon/DevOps-Bash-tools/actions/workflows | jq.
#  args: /repos/:user/:repo/actions/workflows | jq.
#
#  Author: Hari Sekhon
#  Date: 2020-02-12 23:43:00 +0000 (Wed, 12 Feb 2020)
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
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the GitHub.com API

Automatically handles authentication via environment variables \$GITHUB_USERNAME / \$GITHUB_USER
and \$GITHUB_TOKEN / \$GITHUB_PASSWORD (the latter is deprecated)

Can specify \$CURL_OPTS for options to pass to curl or provide them as arguments


Set up a personal access token here:

    https://github.com/settings/tokens


API Reference:

    https://docs.github.com/en/rest/reference


Examples:


# Get currently authenticated user:

    ${0##*/} /user


# Get a specific user:

    ${0##*/} /users/HariSekhon


# List a user's GitHub repos:

    ${0##*/} /users/HariSekhon/repos


# Get the GitHub Actions workflows for a given repo:

    ${0##*/} /repos/HariSekhon/DevOps-Bash-tools/actions/workflows


For convenience you can even copy and paste out of the documentation literally and have the script auto-determine the right settings. The following tokens in the form :token, <token>, {token} are replaced:

Placeholders replaced by \$GITHUB_USERNAME / \$GITHUB_USER:                 owner, username, user
Placeholders replaced by the local repo name of the current directory:    repo

    ${0##*/} /repos/:user/:repo/actions/workflows
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://api.github.com"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

user="${GITHUB_USERNAME:-${GITHUB_USER:-}}"
if [ -z "$user" ]; then
    user="$(git remote -v 2>/dev/null | awk '/https:\/\/.+@github\.com/{print $2; exit}' | sed 's|https://||;s/@.*//;s/:.*//' || :)"
    # curl_auth.sh does this automatically
    #if [ -z "$user" ]; then
    #    user="${USERNAME:${USER:-}}"
    #fi
fi

PASSWORD="${GITHUB_PASSWORD:-${GITHUB_TOKEN:-}}"

if [ -z "${PASSWORD:-}" ]; then
    PASSWORD="$(git remote -v | awk '/https:\/\/[[:alnum:]]+@github\.com/{print $2; exit}' | sed 's|https://||;s/@.*//')"
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

url_path="${url_path//https:\/\/api.github.com}"
url_path="${url_path##/}"

# for convenience of straight copying and pasting out of documentation pages

repo=$(git_repo | sed 's/.*\///')

if [ -n "$user" ]; then
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
url_path="${url_path/:repo/$repo}"
url_path="${url_path/<repo>/$repo}"
url_path="${url_path/\{repo\}/$repo}"

"$srcdir/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
