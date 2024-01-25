#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
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

# https://docs.bitbucket.com/ee/api/pipeline_level_variables.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds / updates Bitbucket Pipelines repo-level secured environment variable(s) from args or stdin

If no second argument is given, reads environment variables from standard input, one per line in 'key=value' format or 'export key=value' shell format

Workspace is case insensitive
Repo slug is case sensitive and must be in lowercase
Variable keys are case-sensitive - a change in case will create a new one

Examples:

    ${0##*/} HariSekhon/devops-bash-tools AWS_ACCESS_KEY_ID=AKIA...

    echo AWS_ACCESS_KEY_ID=AKIA... | ${0##*/} HariSekhon/devops-bash-tools


    Loads both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY via stdin:

        aws_csv_creds.sh credentials_exported.csv | ${0##*/} HariSekhon/devops-bash-tools
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<workspace>/<repo_slug> [<key>=<value> <key2>=<value2> ...]"

help_usage "$@"

min_args 1 "$@"

workspace_repo_slug="$1"
shift || :

existing_env_vars="$("$srcdir/bitbucket_api.sh" "/repositories/$workspace_repo_slug/pipelines_config/variables/" | jq -r '.values[] | [.key, .uuid] | @tsv')"

add_env_var(){
    local env_var="$1"
    parse_export_key_value "$env_var"
    # shellcheck disable=SC2154
    if grep -q "^${key}[[:space:]]" <<< "$existing_env_vars"; then
        local variable_uuid
        variable_uuid="$(awk "/^${key}[[:space:]]/{print \$2}" <<< "$existing_env_vars" | sed 's/{//;s/}//')"
        timestamp "updating Bitbucket environment variable '$key' in repo '$workspace_repo_slug'"
        "$srcdir/bitbucket_api.sh" "/repositories/$workspace_repo_slug/pipelines_config/variables/%7B${variable_uuid}%7D" -X PUT -d "{\"key\": \"$key\", \"value\": \"$value\", \"secured\": true}"
    else
        timestamp "adding Bitbucket environment variable '$key' to repo '$workspace_repo_slug'"
        "$srcdir/bitbucket_api.sh" "/repositories/$workspace_repo_slug/pipelines_config/variables/" -X POST -d "{\"key\": \"$key\", \"value\": \"$value\", \"secured\": true}"
    fi
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
