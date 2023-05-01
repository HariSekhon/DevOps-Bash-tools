#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: hari-test-cli-secret-text mySecretText "" "" "My Secret Text"
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
Creates or Updates a Jenkins Secret Text Credential in the given credential store and domain

Defaults to the 'system::system::jenkins' provider store and global domain '_'

If credential id and secret text aren't given as arguments, then reads from stdin, reading in KEY=VALUE
or standard shell export format - useful for piping from tools like aws_csv_creds.sh

In cases where you are reading secrets from stdin, you can set the store and domain via the environment variables
\$JENKINS_SECRET_STORE and \$JENKINS_SECRET_DOMAIN

Tested on Jenkins 2.319 with Credentials plugin 2.5

Uses the adjacent jenkins_cli.sh - see there for authentication details


Examples:

    # create a credential with id 'aws-access-key-id', and text 'AKIA...':

        ${0##*/} aws-access-key-id AKIA...

    # with a description, leaving the store and domain as the default global one:

        ${0##*/} aws-access-key-id AKIA... '' '' 'My AWS Access Key ID'

    # or piped from standard input:

        # export JENKINS_SECRET_STORE and JENKINS_SECRET_DOMAIN if using stdin but not using system global store

        echo 'AWS_ACCESS_KEY_ID=AKIA...' | ${0##*/}
        echo 'AWS_SECRET_ACCESS_KEY=...' | ${0##*/}

    # using aws_csv_creds.sh to load the credentials from a standard AWS credential download:

        aws_csv_creds.sh ~/.aws/keys/downloaded_access_key_creds.csv | ${0##*/}
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<credential_id> <secret_text> <store> <domain> <description>]"

help_usage "$@"

id="${1:-}"
secret="${2:-}"
store="${3:-${JENKINS_SECRET_STORE:-system::system::jenkins}}"
domain="${4:-${JENKINS_SECRET_DOMAIN:-_}}"
description="${5:-}"

set_credential(){
    local key_value="$1"
    local description="${2:-}"
    parse_export_key_value "$key_value"
    # key/value are exported by above function
    # shellcheck disable=SC2154
    local id="$key"
    # shellcheck disable=SC2154
    local secret="$value"
    if "$srcdir/jenkins_cli.sh" get-credentials-as-xml "$store" "$domain" "$id" &>/dev/null; then
        "$srcdir/jenkins_cred_cli_update_secret_text.sh" "$id" "$secret" "$store" "$domain" "$description"
    else
        "$srcdir/jenkins_cred_cli_add_secret_text.sh" "$id" "$secret" "$store" "$domain" "$description"
    fi
}

if [ -n "$secret" ]; then
    set_credential "$id"="$secret" "$description"
else
    while read -r id_secret description; do
        set_credential "$id_secret" "$description"
    done < <(sed 's/^[[:space:]]*export[[:space:]]*//; /^[[:space:]]*$/d')
fi
