#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-15 23:27:44 +0100 (Sat, 15 Aug 2020)
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
#  args: /users/:id/projects | jq .
#  args: /users/$(gitlab_api.sh /users?username=harisekhon | jq -r .[].id) | jq .
#  args: /users/HariSekhon/projects | jq .
#  args: /projects/:id | jq .
#  args: /projects/HariSekhon%2FDevOps-Bash-tools/pipelines | jq .
#  args: /projects/:id/pipelines | jq .

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the GitLab.com API (v4)

Can specify \$CURL_OPTS for options to pass to curl, or pass them as arguments to the script

Automatically handles authentication via environment variable \$GITLAB_TOKEN


You must set up a personal access token here:

    https://gitlab.com/profile/personal_access_tokens


API Reference:

    https://docs.gitlab.com/ee/api/api_resources.html


Examples:


# Get currently authenticated user:

    ${0##*/} /user


# List a user's GitLab projects (repos):

    ${0##*/} /users/HariSekhon/projects


Specify project ID or name (url-encoded otherwise will return 404 and fail to find project)


# Update a project's description:

    ${0##*/} /projects/HariSekhon%2FDevOps-Bash-tools -X PUT -d 'description=test'


# List a project's CI pipelines, sorted by newest run first:

    ${0##*/} /projects/HariSekhon%2FDevOps-Bash-tools/pipelines


# List a project's jobs (contains the status and pipeline reference):

    ${0##*/} /projects/HariSekhon%2FDevOps-Bash-tools/jobs


# List a project's jobs for a specific pipeline:

    ${0##*/} /projects/HariSekhon%2FDevOps-Bash-tools/pipelines/<pipeline_id>/jobs


# List a project's deployments:

    ${0##*/} /projects/HariSekhon%2FDevOps-Bash-tools/deployments


# Get details for a single job:

    ${0##*/} /projects/:id/jobs/:job_id


# Get a project's remote mirrors:

    ${0##*/} /projects/HariSekhon%2FDevOps-Bash-tools/remote_mirrors


# Get log for a specific job:

    ${0##*/} /projects/:id/jobs/:job_id/trace


# List recent events such as pushes, by the currently authenticated user:

    ${0##*/} /events


For convenience you can even copy and paste out of the documentation literally and have the script auto-determine the right settings (due to the context variation of the GitLAB API documentation tokens this is only done for users and projects only at this time)

The following placeholders are replaced if the environment variables are available or inferred fro mthe local git repo. The format can be one of {token}, <token> :token

\$GITLAB_USERNAME / \$GITLAB_USER:                           owner, username, user, /users/:id
local repo name of the current directory:                  repo
local full 'user/repo' name of the current directory:      project, /projects/:id
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://gitlab.com/api/v4"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

url_path="${1:-}"
shift

url_path="${url_path##*:\/\/api.gitlab.com\/api\/v4}"
url_path="${url_path##/}"

# for convenience of straight copying and pasting out - but documentation uses :id in different contexts to mean project id or user id so this is less useful than in github_api.sh

user="${GITLAB_USERNAME:-${GITLAB_USER:-}}"
if [ -z "$user" ]; then
    user="$(git remote -v 2>/dev/null | awk '/https:\/\/.+@gitlab\.com/{print $2; exit}' | sed 's|https://||;s/@.*//;s/:.*//' || :)"
fi

if [ -n "$user" ]; then
    export USERNAME="$user"
fi

if [ -z "${GITLAB_TOKEN:-}" ]; then
    GITLAB_TOKEN="$(git remote -v 2>/dev/null | awk '/https:\/\/.+@gitlab\.com/{print $2; exit}' | sed 's|https://||;s/@.*//;s/.*://' || :)"
fi

if [ -z "$GITLAB_TOKEN" ]; then
    usage "GITLAB_TOKEN not defined and could not infer from local repo"
fi

project="$(git_repo 2>/dev/null || :)"
repo="$(sed 's/.*\///' <<< "$project")"
project="${project//\//%2F}" # cheap url encode slash

if [ -n "$user" ]; then
    url_path="${url_path/\{owner\}/$user}"
    url_path="${url_path/<owner>/$user}"
    url_path="${url_path/:owner/$user}"
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
url_path="${url_path/\{project\}/$project}"
url_path="${url_path/<project>/$project}"
url_path="${url_path/:project/$project}"
url_path="${url_path/projects\/:id/projects\/$project}"
url_path="${url_path/users\/:id/users\/$user}"

export TOKEN="$GITLAB_TOKEN"

# can also leave out to use OAuth compliant header "Authorization: Bearer <token>"
export CURL_AUTH_HEADER="Private-Token:"

"$srcdir/curl_auth.sh" "$url_base/$url_path" "${CURL_OPTS[@]}" "$@"
