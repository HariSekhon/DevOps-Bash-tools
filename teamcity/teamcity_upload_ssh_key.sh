#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-01-11 13:14:37 +0000 (Mon, 11 Jan 2021)
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
Uploads SSH private key to TeamCity via the Web UI

There's no TeamCity Rest API support for SSH key management at the time of writing so this script posts to the Web UI :'-(

    https://youtrack.jetbrains.com/issue/TW-42311

If no project is specified as the 3rd arg, uploads to the Root project:

    \$TEAMCITY_URL/admin/editProject.html?projectId=_Root&tab=ssh-manager#


This is useful for (re)connecting VCS configurations using SSH auth which can be used to load entire teamcity projects


The SSH private key must be in standard PEM format to be accepted by TeamCity (generated via 'ssh-keygen -m PEM') rather than new non-standard OpenSSH format

    https://youtrack.jetbrains.com/issue/TW-53615

Idempotent - if the named SSH key already exists, will replace it and exit with success code zero
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<key_file> [<key_name> <teamcity_project_id>]"

help_usage "$@"

min_args 1 "$@"

ssh_private_key="$1"

name="${2:-${ssh_private_key##*/}}"

# defaults to the Root project because this is the best place to use external VCS connections and auth from, to prevent them being reset and broken by import from VCS which by default excludes secrets
project_id="${3:-_Root}"

url_path=""

if [ -n "${TEAMCITY_URL:-}" ]; then
    url_base="${TEAMCITY_URL%%/}"
else
    protocol="http"
    if [ -n "${TEAMCITY_SSL:-}" ]; then
        protocol="https"
    fi
    [ -n "${TEAMCITY_HOST:-}" ] || usage "neither \$TEAMCITY_URL nor \$TEAMCITY_HOST defined in environment"
    host="$TEAMCITY_HOST"
    port="${TEAMCITY_PORT:-8111}"
    url_base="$protocol://$host:$port"
fi

teamcity_curl_auth(){
    local url_path="$1"
    shift || :
    local curl_opts=(-sS --fail --connect-timeout 5)
    # use superuser token override to support teamcity.sh when token has already been created but we cannot get it's key value out of the API, so need to continue using superuser token
    if [ -n "${TEAMCITY_SUPERUSER_TOKEN:-}" ]; then
        # XXX: superuser token can only be used with blank user which cannot be used with curl_auth.sh
        curl -u ":$TEAMCITY_SUPERUSER_TOKEN" "$url_base/$url_path" "${curl_opts[@]}" "$@"
    else
        "$srcdir/../bin/curl_auth.sh" "$url_base/$url_path" "${curl_opts[@]}" "$@"
    fi
}


timestamp "Uploading TeamCity SSH key '$ssh_private_key' to project '$project_id' called '$name' on TeamCity server at '$url_base'"
output="$(teamcity_curl_auth /admin/sshKeys.html -X POST \
                                                 -F "action=createSshKey" \
                                                 -F "projectId=$project_id" \
                                                 -F "fileName=$name" \
                                                 -F "file:fileToUpload=@$ssh_private_key"
)"
echo
if grep -i error <<< "$output"; then
    echo
    timestamp "ERROR: TeamCity SSH key upload FAILED"
    exit 1
fi

timestamp "TeamCity SSH key '$name' created in '$project_id' project"
