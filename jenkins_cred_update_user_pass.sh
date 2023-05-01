#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: hari-test-api-user-pass hari mypassword "" "" "My Updated Username + Password"
#
#  Author: Hari Sekhon
#  Date: 2022-06-28 18:34:34 +0100 (Tue, 28 Jun 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://github.com/jenkinsci/credentials-plugin/blob/master/docs/user.adoc#creating-a-credentials

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Updates a Jenkins Username/Password Credential in the given credential store and domain

Defaults to the 'system' provider's store and global domain '_'

If credential id, user and password aren't given as arguments, then reads from stdin, reading in KEY=VALUE
or standard shell export format - useful for piping from tools like aws_csv_creds.sh

If standard input does not have an id field, the id will be generated from the username lowercased with '-user-pass' appended.

In cases where you are reading secrets from stdin, you can set the store and domain via the environment variables
\$JENKINS_SECRET_STORE and \$JENKINS_SECRET_DOMAIN

Tested on Jenkins 2.319 with Credentials plugin 2.5

Uses the adjacent jenkins_api.sh - see there for authentication details


Examples:

    # update a credential with id 'hari-user-pass', username 'hari' and password 'mypassword':

        ${0##*/} hari-user-pass hari mypassword

    # with a description, leaving the store and domain as the default global one:

        ${0##*/} hari-user-pass hari mypassword '' '' 'My Username + Password'

    # or piped from standard input:

        #export JENKINS_SECRET_STORE and JENKINS_SECRET_DOMAIN if using stdin but not using system global store

        echo 'hari=mypassword' | ${0##*/}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<credential_id> <user> <password> <store> <domain> <description> <curl_options>]"

help_usage "$@"

id="${1:-}"
user="${2:-}"
password="${3:-}"
store="${4:-${JENKINS_SECRET_STORE:-system}}"
domain="${5:-${JENKINS_SECRET_DOMAIN:-_}}"
description="${6:-}"
for _ in {1..6}; do shift || : ; done
curl_args=("$@")

update_credential(){
    local id="$1"
    local key_value="$2"
    local description="${3:-}"
    parse_export_key_value "$key_value"
    # key/value are exported by above function
    # shellcheck disable=SC2154
    local user="$key"
    # shellcheck disable=SC2154
    local password="$value"
    local domain_name="$domain"
    if [ "$domain_name" = '_' ]; then
        domain_name='GLOBAL'
    fi
    local xml="<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>$domain_name</scope>
  <id>$id</id>
  <description>$description</description>
  <username>$user</username>
  <password>$password</password>
  <usernameSecret>false</usernameSecret>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>"
    timestamp "Updating Jenkins username/password credential '$id' in store '$store' domain '$domain_name'"
    "$srcdir/jenkins_api.sh" "/credentials/store/$store/domain/$domain/credential/$id/config.xml" -X POST -H "Content-Type: application/xml" -d @<(cat <<< "$xml") ${curl_args:+"${curl_args[@]}"}
    timestamp "Secret '$id' updated"
}

if [ -n "$password" ]; then
    update_credential "$id" "$user"="$password" "$description"
else
    while read -r id user_password; do
        if [ -z "${user_password:-}" ] && [[ "$id" =~ = ]]; then
            user_password="$id"
            id="${id%%=*}-user-pass"
            id="$(tr '[:upper:]' '[:lower:]' <<< "$id")"
        else
            timestamp "WARNING: invalid line detected, skipping creating credential"
            continue
        fi
        update_credential "$id" "$user_password" "$description"
    done < <(sed 's/^[[:space:]]*export[[:space:]]*//; /^[[:space:]]*$/d')
fi
