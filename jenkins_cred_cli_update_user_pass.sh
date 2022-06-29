#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: haritest-cli-credential hari-updated-user my-updated-password
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Updates the given Jenkins credential in the given credential store and domain

Defaults to the 'system::system::jenkins' provider store and global domain '_'

Uses the adjacent jenkins_cli.sh - see there for authentication details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<credential_id> <user> <password> <store> <domain> <description>]"

help_usage "$@"

id="${1:-}"
user="${2:-}"
password="${3:-}"
store="${4:-system::system::jenkins}"
domain="${5:-_}"
description="${6:-}"

update_credential(){
    local id="$1"
    local user="$2"
    local password="$3"
    xml="<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>$id</id>
  <description>$description</description>
  <username>$user</username>
  <password>$password</password>
  <usernameSecret>false</usernameSecret>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>"
    "$srcdir/jenkins_cli.sh" update-credentials-by-xml "$store" "$domain" "$id" <<< "$xml"
}

if [ -n "$password" ]; then
    update_credential "$id" "$user" "$password"
else
    # XXX: switch this to accepting standard 'export KEY=VALUE' format for pipe chaining with other tools
    while read -r id user password; do
        [ -n "$password" ] || continue
        update_credential "$id" "$user" "$password"
    done
fi
