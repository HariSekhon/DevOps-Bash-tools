#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: hari-test-cli-ssh-key hari ~/.ssh/id_rsa "" "" "My SSH Key"
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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates a Jenkins SSH Key Credential in the given credential store and domain

Defaults to the 'system::system::jenkins' provider store and global domain '_'

If credential id, user and private_key aren't given as arguments, then reads from stdin, reading in KEY=VALUE
or standard shell export format - useful for piping from tools like aws_csv_creds.sh

If standard input does not have an id field, the id will be generated from the username lowercased with '-ssh-key' appended

In cases where you are reading secrets from stdin, you can set the store and domain via the environment variables
\$JENKINS_SECRET_STORE and \$JENKINS_SECRET_DOMAIN

Tested on Jenkins 2.319 with Credentials plugin 2.5

Uses the adjacent jenkins_cli.sh - see there for authentication details


Examples:

    # create a credential with id 'hari-ssh-key', username 'hari' and load the private key contents from my ~/.ssh/id_rsa file:

        ${0##*/} hari-ssh-key hari ~/.ssh/id_rsa

    # with a description, leaving the store and domain as the default global one:

        ${0##*/} hari-ssh-key hari ~/.ssh/id_rsa '' '' 'My SSH Key'

    # or piped from standard input:

        #export JENKINS_SECRET_STORE and JENKINS_SECRET_DOMAIN if using stdin if not using system global store

        echo hari=~/.ssh/id_rsa | ${0##*/}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<credential_id> <user> <private_key_or_file> <store> <domain> <description>]"

help_usage "$@"

id="${1:-}"
user="${2:-}"
private_key="${3:-}"
store="${4:-${JENKINS_SECRET_STORE:-system::system::jenkins}}"
domain="${5:-${JENKINS_SECRET_DOMAIN:-_}}"
description="${6:-}"

create_credential(){
    local id="$1"
    local key_value="$2"
    local description="${3:-}"
    parse_export_key_value "$key_value"
    # key/value are exported by above function
    # shellcheck disable=SC2154
    local user="$key"
    # shellcheck disable=SC2154
    local private_key="$value"
    if [ -f "$private_key" ]; then
        timestamp "Reading private key from file '$private_key'"
        private_key="$(cat "$private_key")"
    fi
    local domain_name="$domain"
    if [ "$domain_name" = '_' ]; then
        domain_name='GLOBAL'
    fi
    local xml="<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
  <scope>$domain</scope>
  <id>$id</id>
  <description>$description</description>
  <username>$user</username>
  <usernameSecret>false</usernameSecret>
  <privateKeySource class=\"com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource\">
    <privateKey>$private_key</privateKey>
  </privateKeySource>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>"
    timestamp "Creating Jenkins ssh key credential '$id' in store '$store' domain '$domain_name'"
    "$srcdir/jenkins_cli.sh" create-credentials-by-xml "$store" "$domain" <<< "$xml"
    timestamp "Secret '$id' created"
}

if [ -n "$private_key" ]; then
    create_credential "$id" "$user"="$private_key" "$description"
else
    while read -r id user_privatekey description; do
        if [ -z "${user_privatekey:-}" ] && [[ "$id" =~ = ]]; then
            user_privatekey="$id"
            id="${id%%=*}-ssh-key"
            id="$(tr '[:upper:]' '[:lower:]' <<< "$id")"
        else
            timestamp "WARNING: invalid line detected, skipping creating credential"
            continue
        fi
        create_credential "$id" "$user_privatekey" "$description"
    done < <(sed 's/^[[:space:]]*export[[:space:]]*//; /^[[:space:]]*$/d')
fi
