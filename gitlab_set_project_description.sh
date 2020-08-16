#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 09:52:29 +0100 (Sun, 16 Aug 2020)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sets the description of a GitLab.com project via the GitLab API

Uses the adjcent script gitlab_api.sh, see there for authentication details

\$CURL_OPTS can be set to provide extra arguments to curl


Project can be the full project name (eg. HariSekhon/DevOps-Bash-tools) or the project ID

Project username prefix can be omitted, will use \$GITLAB_USER if available, otherwise will query the GitLab API to determine it

Automatically url encodes the entire project name for you since the GitLab API will 404 fail to find the project otherwise


Example:

${0##*/} HariSekhon/DevOps-Bash-tools    my new description
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project> <description>"

help_usage "$@"

min_args 2 "$@"

project="$1"

description="${*:2}"

if ! [[ "$project" =~ / ]]; then
    log "no username prefix in project, attempting to infer"
    if [ -n "${GITLAB_USER:-}" ]; then
        user="$GITLAB_USER"
        log "using username '$user' from \$GITLAB_USER"
    else
        log "querying GitLab API for currently authenticated username"
        user="$("$srcdir/gitlab_api.sh" /user | jq -r .username)"
        log "GitLab API returned username '$user'"
    fi
    project="$user/$project"
fi

timestamp "setting GitLab project '$project' description to '$description'" >&2

# url-encode project name otherwise GitLab API will fail to find project and return 404
project="$("$srcdir/urlencode.sh" <<< "$project")"

"$srcdir/gitlab_api.sh" "/projects/$project" -X PUT --data "description=$description" >/dev/null
