#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: github/HariSekhon/DevOps-Bash-tools haritest=stuff
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

# https://circleci.com/docs/api/v2/#operation/createEnvVar

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds / updates CircleCI project-level environment variable(s) from args or stdin

If no second argument is given, reads environment variables from standard input, one per line in 'key=value' format or 'export key=value' shell format

Examples:

    ${0##*/} github/HariSekhon/DevOps-Bash-tools AWS_ACCESS_KEY_ID=AKIA...

    echo AWS_ACCESS_KEY_ID=AKIA... | ${0##*/} github/HariSekhon/DevOps-Bash-tools


    Loads both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY via stdin:

        aws_csv_creds.sh credentials_exported.csv | ${0##*/} github/HariSekhon/DevOps-Bash-tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project_slug> [<key>=<value> <key2>=<value2> ...]"

help_usage "$@"

min_args 1 "$@"

project_slug="$1"
shift || :

project_slug="${project_slug##/}"
project_slug="${project_slug%%/}"


if ! [[ "$project_slug" =~ ^[[:alnum:]]+/[[:alnum:]-]+/[[:alnum:]-]+$ ]]; then
    usage "project-slug given '$project_slug' does not conform to <vcs>/<user_or_org>/<repo> format"
fi

add_env_var(){
    local env_var="$1"
    parse_export_key_value "$env_var"
    # shellcheck disable=SC2154
    timestamp "adding/updating CircleCI environment variable '$key' to project '$project_slug'"
    # shellcheck disable=SC2154
    # XXX: this is a POST at the project level but a PUT at the context level (else 404 error)
    "$srcdir/circleci_api.sh" "/project/$project_slug/envvar" -X POST -d "{\"name\": \"$key\", \"value\": \"$value\"}" | jq .
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
