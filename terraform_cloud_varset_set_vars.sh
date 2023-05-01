#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: $TERRAFORM_ORGANIZATION $TERRAFORM_VARSET_ID haritest=myvalue
#
#  Author: Hari Sekhon
#  Date: 2021-12-21 13:30:39 +0000 (Tue, 21 Dec 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://www.terraform.io/cloud-docs/api-docs/variable-sets

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Adds / updates Terraform Cloud variables for a given variable set from args or stdin

By default, creates variables as Environment Variables and marks them as Sensitive for safety as the primary use case for this code was easy uploading AWS access key credentials from things like aws_csv_creds.sh

If you want to create Terraform variables instead:

    export TERRAFORM_VARIABLES=1
    export TERRAFORM_VARIABLES_HCL=1  # mark the variables as HCL code (implies TERRAFORM_VARIABLES=1)

If you want to mark the variables as non-sensitive:

    export TERRAFORM_VARIABLES_SENSITIVE=false


See terraform_cloud_organizations.sh to get a list of organization IDs
See terraform_cloud_varsets.sh to get a list of variable sets and their IDs


Examples:

    ${0##*/} {varset_id} AWS_ACCESS_KEY_ID=AKIA...

    echo AWS_ACCESS_KEY_ID=AKIA... | ${0##*/} {varset_id}


    Loads both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY via stdin:

        aws_csv_creds.sh credentials_exported.csv | ${0##*/} {varset_id}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<organization> <varset_id> [<key>=<value> <key2>=<value2> ...]"

help_usage "$@"

min_args 2 "$@"

org="$1"
varset_id="$2"
shift || :
shift || :

if ! [[ "$varset_id" =~ ^varset-[[:alnum:]]+$ ]]; then
    usage "invalid varset id given: $varset_id - should be in format varset-[[:alnum:]]+"
fi

if [ -n "${TERRAFORM_VARIABLES_HCL:-}" ]; then
    TERRAFORM_VARIABLES=1
    hcl=true
else
    hcl=false
fi

if [ -n "${TERRAFORM_VARIABLES:-}" ]; then
    category="terraform"
else
    category="env"
fi

if [ "${TERRAFORM_VARIABLES_SENSITIVE:-}" = false ]; then
    sensitive=false
else
    sensitive=true
fi

varsets_env_vars="$("$srcdir/terraform_cloud_varset_vars.sh" "$org" "$varset_id")"

add_env_var(){
    local env_var="$1"
    parse_export_key_value "$env_var"
    local id
    # shellcheck disable=SC2154
    id="$(awk "\$1 == \"$varset_id\" && \$4 == \"env\" && \$6 == \"$key\" {print \$3}" <<< "$varsets_env_vars")"
    varset_name="$(awk "\$1 == \"$varset_id\" {print \$2; exit}" <<< "$varsets_env_vars")"
    if [ -n "$id" ]; then
        timestamp "updating Terraform environment variable '$key' (id: '$id') in variable set '$varset_name' (id '$varset_id')"
        # shellcheck disable=SC2154
        "$srcdir/terraform_cloud_api.sh" "/varsets/$varset_id/relationships/vars/$id" \
            -X PATCH \
            -H "Content-Type: application/vnd.api+json" \
            -d "{
                    \"data\": {
                        \"id\": \"$id\",
                        \"attributes\": {
                            \"key\": \"$key\",
                            \"value\": \"$value\",
                            \"category\": \"$category\",
                            \"hcl\": $hcl,
                            \"sensitive\": $sensitive
                        },
                        \"type\":\"vars\"
                    }
                }" > /dev/null
        #echo  # JSON output doesn't end in a newline
    else
        timestamp "adding Terraform environment variable '$key' in variable set '$varset_name' (id '$varset_id')"
        "$srcdir/terraform_cloud_api.sh" "/varsets/$varset_id/relationships/vars" \
            -X POST \
            -H "Content-Type: application/vnd.api+json" \
            -d "{
                    \"data\": {
                        \"attributes\": {
                            \"key\": \"$key\",
                            \"value\": \"$value\",
                            \"category\": \"$category\",
                            \"hcl\": $hcl,
                            \"sensitive\": $sensitive
                        },
                        \"type\":\"vars\"
                    }
                }" |
                jq_debug_pipe_dump >/dev/null
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
