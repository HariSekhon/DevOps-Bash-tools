#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 09:52:29 +0100 (Sun, 16 Aug 2020)
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
Sets the description of a GitLab.com project via the GitLab API

Uses the adajcent script gitlab_api.sh, see there for authentication details

\$CURL_OPTS can be set to provide extra arguments to curl


Project can be the full project name (eg. HariSekhon/DevOps-Bash-tools) or the project ID

Project username prefix can be omitted, will use \$GITLAB_USER if available, otherwise will query the GitLab API to determine it

Automatically url encodes the project name and description for you since the GitLab API will return 404 and fail to find the project name if not url encoded


Example:

    ${0##*/} HariSekhon/DevOps-Bash-tools    my new description


If no args are given, will read project and description from standard input for easy chaining with other tools, can easily update multiple repositories this way, one project + description per line:

    echo <project> <description> | ${0##*/}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project> <description>"

help_usage "$@"

#min_args 2 "$@"

set_project_description(){
    local project="$1"
    local description="${*:2}"

    if ! [[ "$project" =~ / ]]; then
        log "No username prefix in project '$project', will auto-add it"
        # reuse gitlab_user between function calls for efficiency to save additional queries to the GitLab API
        if [ -z "${gitlab_user:-}" ]; then
            log "Attempting to infer username"
            if [ -n "${GITLAB_USER:-}" ]; then
                gitlab_user="$GITLAB_USER"
                log "Using username '$gitlab_user' from \$GITLAB_USER"
            else
                log "Querying GitLab API for currently authenticated username"
                gitlab_user="$("$srcdir/gitlab_api.sh" /user | jq -r .username)"
                log "GitLab API returned username '$gitlab_user'"
            fi
        fi
        project="$gitlab_user/$project"
    fi

    timestamp "Setting GitLab project '$project' description to '$description'"

    # url-encode project name otherwise GitLab API will fail to find project and return 404
    project="$("$srcdir/../bin/urlencode.sh" <<< "$project")"
    # don't URL encode this now that it is inside JSON
    #description="$("$srcdir/../bin/urlencode.sh" <<< "$description")"
    # just strip quotes to protect the JSON
    description="${description//\"/}"

    # this used to work with just -d "description=$description" when Accept and Content-Type headers were omitted
    # but since curl_api_opts auto-sets headers to application/json this must be json or else get 400 bad request error
    "$srcdir/gitlab_api.sh" "/projects/$project" -X PUT --data "{ \"description\": \"$description\" }" >/dev/null
}

if [ $# -gt 0 ]; then
    if [ $# -lt 2 ]; then
        usage
    fi
    set_project_description "$@"
else
    while read -r project description; do
        [ -n "$project" ] || continue
        [ -n "$description" ] || continue
        set_project_description "$project" "$description"
    done
fi
