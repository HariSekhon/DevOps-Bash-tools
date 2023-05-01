#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: HariSekhon/DevOps-Bash-tools haritest=stuff
#
#  Author: Hari Sekhon
#  Date: 2021-12-03 17:41:23 +0000 (Fri, 03 Dec 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.gitlab.com/ee/api/project_level_variables.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds / updates GitLab CI project-level masked environment variable(s) from args or stdin

If no second argument is given, reads environment variables from standard input, one per line in 'key=value' format or 'export key=value' shell format

If GITLAB_VARIABLES_PROTECTED=1 is set in the environment, then will create a protected environment variable which is only available to protected branches or tags
If GITLAB_VARIABLES_UNMASKED=1 is set in the environment, then environment variables will not be masked

Examples:

    ${0##*/} github/HariSekhon/DevOps-Bash-tools AWS_ACCESS_KEY_ID=AKIA...

    echo AWS_ACCESS_KEY_ID=AKIA... | ${0##*/} HariSekhon/DevOps-Bash-tools


    Loads both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY via stdin:

        aws_csv_creds.sh credentials_exported.csv | ${0##*/} HariSekhon/DevOps-Bash-tools


XXX: Caveat - GitLab only masks variables 8 characters or longer and they are retrievable in plaintext via the API - better to use a secrets value if possible
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project_slug_or_id> [<key>=<value> <key2>=<value2> ...]"

help_usage "$@"

min_args 1 "$@"

project_slug="$1"
shift || :

if ! [[ "$project_slug" =~ ^[[:digit:]]+$|^[[:alnum:]-]+/[[:alnum:]-]+$ ]]; then
    usage "project-slug given '$project_slug' does not conform to id or <user_or_org>/<repo> format"
fi

project_slug="${project_slug//\//%2F}"

existing_env_vars="$("$srcdir/gitlab_api.sh" "projects/$project_slug/variables" | jq -r '.[].key')"

protected=false
if [ -n "${GITLAB_VARIABLES_PROTECTED:-}" ]; then
    protected=true
fi

add_env_var(){
    local env_var="$1"
    parse_export_key_value "$env_var"
    local masked=true
    # shellcheck disable=SC2154
    if [ "${GITLAB_VARIABLES_UNMASKED:-}" = 1 ]; then
        echo "WARNING: value for key '$key' will not be masked because GITLAB_VARIABLES_UNMASKED is set in the environment" >&2
        masked=false
    elif [ "${#value}" -lt 8 ]; then  # avoids 400 errors from the API if sending < 8 chars with masked=true
        echo "WARNING: value for key '$key' is less than 8 characters so can't be masked in GitLab" >&2
        masked=false
    fi
    # shellcheck disable=SC2154
    if grep -Fxq "$key" <<< "$existing_env_vars"; then
        timestamp "updating GitLab environment variable '$key' in project '$project_slug'"
        "$srcdir/gitlab_api.sh" "projects/$project_slug/variables/$key?masked=$masked&protected=$protected" -X PUT \
            -F "value=$value" \
            -H 'Content-Type: multipart/form-data'
    else
        timestamp "adding GitLab environment variable '$key' to project '$project_slug'"
                                          # could also use a project_id
        "$srcdir/gitlab_api.sh" "projects/$project_slug/variables?masked=$masked&protected=$protected" -X POST \
            -F "key=$key" \
            -F "value=$value" \
            -H 'Content-Type: multipart/form-data'
            # must override the default -H 'Content-Type: application/json' in curl_api_opts() in lib/utils.sh  to avoid 400 or 406 errors from the API
    fi |
    jq '.value = "REDACTED"'  # echo's back the variable value in plaintext
}


if [ $# -gt 0 ]; then
    for arg in "$@"; do
        add_env_var "$arg"
    done
else
    while read -r line; do
        add_env_var "$line"
    done
fi
