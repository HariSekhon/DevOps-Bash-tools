#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  arg: :workspace
#
#  Author: Hari Sekhon
#  Date: 2021-12-21 13:30:39 +0000 (Tue, 21 Dec 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds / updates Terraform Cloud workspace variables for a given workspace id from args or stdin

Variables are marked as sensitive as the primary use case for this is uploading AWS access key credentials from things like aws_csv_creds.sh:

Examples:

    ${0##*/} {workspace_id} AWS_ACCESS_KEY_ID=AKIA...

    echo AWS_ACCESS_KEY_ID=AKIA... | ${0##*/} {workspace_id}


    Loads both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY via stdin:

        aws_csv_creds.sh credentials_exported.csv | ${0##*/} {workspace_id}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<workspace_id> [<key>=<value> <key2>=<value2> ...]"

help_usage "$@"

min_args 1 "$@"

workspace_id="$1"
shift || :

if [ -z "$workspace_id" ]; then
    usage "no terraform workspace id given"
fi

env_vars="$("$srcdir/terraform_cloud_workspace_vars.sh" "$workspace_id")"

add_env_var(){
    local env_var="$1"
    env_var="${env_var%%#*}"
    env_var="${env_var##[[:space:]]}"
    env_var="${env_var##export}"
    env_var="${env_var##[[:space:]]}"
    if ! [[ "$env_var" =~ ^[[:alpha:]][[:alnum:]_]+=.+$ ]]; then
        usage "invalid environment key=value argument given: $env_var"
    fi
    local name="${env_var%%=*}"
    local value="${env_var#*=}"
    local id
    id="$(awk "\$3 == \"$name\" {print \$1}" <<< "$env_vars")"
    if [ -n "$id" ]; then
        timestamp "updating Terraform environment variable '$name' (id: '$id') in workspace '$workspace_id'"
        "$srcdir/terraform_cloud_api.sh" "/workspaces/$workspace_id/vars/$id" \
            -X PATCH \
            -H "Content-Type: application/vnd.api+json" \
            -d "{
                    \"data\": {
                        \"id\": \"$id\",
                        \"attributes\": {
                            \"key\": \"$name\",
                            \"value\": \"$value\",
                            \"sensitive\": true
                        },
                        \"type\":\"vars\"
                    }
                }" > /dev/null
        #echo  # JSON output doesn't end in a newline
    else
        timestamp "adding Terraform environment variable '$name' in workspace '$workspace_id'"
        "$srcdir/terraform_cloud_api.sh" "/workspaces/$workspace_id/vars" \
            -X POST \
            -H "Content-Type: application/vnd.api+json" \
            -d "{
                    \"data\": {
                        \"attributes\": {
                            \"key\": \"$name\",
                            \"value\": \"$value\",
                            \"category\": \"env\",
                            \"hcl\": false,
                            \"sensitive\": true
                        },
                        \"type\":\"vars\"
                    }
                }" >/dev/null
        #echo  # JSON output doesn't end in a newline
    fi
    echo
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
