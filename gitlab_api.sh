#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-15 23:27:44 +0100 (Sat, 15 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://docs.gitlab.com/ee/api/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Queries the GitLab.com APIv4

Can specify \$CURL_OPTS for options to pass to curl, or pass them as arguments to the script

Automatically handles authentication via environment variable \$GITLAB_TOKEN


You must set up a personal access token here:

https://gitlab.com/profile/personal_access_tokens


API Reference:

https://docs.gitlab.com/ee/api/api_resources.html



Examples:


List a user's GitLab projects (repos):

${0##*/} /users/harisekhon/projects


Update a project's description:

${0##*/} /projects/<id_or_url_encoded_project_name> -X PUT -d 'description=test'

${0##*/} /projects/HariSekhon%2FDevOps-Bash-tools -X PUT -d 'description=test'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

if [ -z "${GITLAB_TOKEN:-}" ]; then
    GITLAB_TOKEN="$(git remote -v | awk '/https:\/\/[[:alnum:]]+@gitlab\.com/{print $2; exit}' | sed 's|https://||;s/@.*//')"
fi

check_env_defined "GITLAB_TOKEN"

help_usage "$@"

min_args 1 "$@"

url_path="${1:-}"
url_path="${url_path//https:\/\/api.github.com}"
url_path="${url_path##/}"

shift

url_base="https://gitlab.com/api/v4"

CURL_OPTS="-sS --fail --connect-timeout 3 ${CURL_OPTS:-}"

# want splitting
# shellcheck disable=SC2086
if is_curl_min_version 7.55; then
    # this trick doesn't work, file descriptor is lost by next line
    #filedescriptor=<(cat <<< "Private-Token: $GITLAB_TOKEN")
    curl ${CURL_OPTS} -H @<(cat <<< "Private-Token: $GITLAB_TOKEN") "$url_base/$url_path" "$@"
else
    # could also use OAuth compliant header "Authorization: Bearer <token>"
    curl ${CURL_OPTS:-} -H "Private-Token: $GITLAB_TOKEN" "$url_base/$url_path" "$@"
fi
