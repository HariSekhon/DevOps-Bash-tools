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

For convenience you can even copy and paste out of the documentation literally and have the script auto-determine the right settings (due to the context variation of the GitLAB API documentation tokens this is only done for users and projects only at this time)

Placeholders replaced by \$GITLAB_USER:  :owner, :user, :username, <user>, <username>, /users/:id
Placeholders replaced by the local repo name of the current directory:  :repo, <repo>
Placeholders replaced by the local full 'user/repo' name of the current directory:  :project, <project>, /projects/:id
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

url_base="https://gitlab.com/api/v4"

CURL_OPTS="-sS --fail --connect-timeout 3 ${CURL_OPTS:-}"

if [ -z "${GITLAB_TOKEN:-}" ]; then
    GITLAB_TOKEN="$(git remote -v | awk '/https:\/\/[[:alnum:]]+@gitlab\.com/{print $2; exit}' | sed 's|https://||;s/@.*//')"
fi

check_env_defined "GITLAB_TOKEN"

help_usage "$@"

min_args 1 "$@"

url_path="${1:-}"
shift

url_path="${url_path//https:\/\/api.github.com}"
url_path="${url_path##/}"

# for convenience of straight copying and pasting out - but documentation uses :id in different contexts to mean project id or user id so this is less useful than in github_api.sh

user="${GITLAB_USER:-${USER:-}}"
project=$(git_repo)
repo=$(sed 's/.*\///' <<< "$project")
project="${project//\//%2F}" # cheap url encode slash

url_path="${url_path/:owner/$USER}"
url_path="${url_path/:user/$USER}"
url_path="${url_path/:username/$USER}"
url_path="${url_path/<user>/$USER}"
url_path="${url_path/<username>/$USER}"
url_path="${url_path/:repo/$repo}"
url_path="${url_path/<repo>/$repo}"
url_path="${url_path/:project/$project}"
url_path="${url_path/<project>/$project}"
url_path="${url_path/projects\/:id/projects\/$project}"
url_path="${url_path/users\/:id/users\/$user}"


# need CURL_OPTS splitting, safer than eval
# shellcheck disable=SC2086
if is_curl_min_version 7.55; then
    # this trick doesn't work, file descriptor is lost by next line
    #filedescriptor=<(cat <<< "Private-Token: $GITLAB_TOKEN")
    curl $CURL_OPTS -H @<(cat <<< "Private-Token: $GITLAB_TOKEN") "$url_base/$url_path" "$@"
else
    # could also use OAuth compliant header "Authorization: Bearer <token>"
    curl $CURL_OPTS -H "Private-Token: $GITLAB_TOKEN" "$url_base/$url_path" "$@"
fi
