#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-17 13:42:12 +0000 (Thu, 17 Dec 2020)
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
Sets the description of a BuildKite pipeline via the BuildKite API

Uses the adajcent script buildkite_api.sh, see there for authentication details


Example:

    ${0##*/} devops-bash-tools    my new description


If no args are given, will read pipeline_slug and description from standard input for easy chaining with other tools, can easily update multiple repositories this way, one pipeline_slug + description per line:

    echo <pipeline_slug> <description> | ${0##*/}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<pipeline_slug> <description>"

help_usage "$@"

#min_args 2 "$@"

set_pipeline_description(){
    local pipeline_slug="$1"
    local description="${*:2}"

    timestamp "Setting BuildKite pipeline '$pipeline_slug' description to '$description'"

    # this used to work with just -d "description=$description" when Accept and Content-Type headers were omitted
    # but since curl_api_opts auto-sets headers to application/json this must be json or else get 400 bad request error
    "$srcdir/buildkite_api.sh" "/organizations/{organization}/pipelines/$pipeline_slug" -X PATCH -d '{"description": "'"$description"'"}' >/dev/null
}

if [ $# -gt 0 ]; then
    if [ $# -lt 2 ]; then
        usage
    fi
    set_pipeline_description "$@"
else
    while read -r pipeline_slug description; do
        [ -n "$pipeline_slug" ] || continue
        [ -n "$description" ] || continue
        set_pipeline_description "$pipeline_slug" "$description"
    done
fi
