#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-21 18:37:01 +0000 (Mon, 21 Mar 2022)
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
Creates a GitLab project (repo) as a mirror import from another repo URL

Would configure auto-mirroring to stay in-sync too but that is a premium feature in the API
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project_name> <repo_url_to_mirror>"

help_usage "$@"

name="$1"
import_url="$2"

#if [ -n "${GITLAB_USER:-}" ]; then
#    user="$GITLAB_USER"
#else
#    # get currently authenticated user
#    user="$("$srcdir/gitlab_api.sh" /user | jq -r .username)"
#fi

#user="$("$srcdir/gitlab_api.sh" "/users?username=$user" | jq -r '.[0].id')"

timestamp "Creating GitLab repo '$name'"
#"$srcdir/gitlab_api.sh" "/projects/user/$user" -X POST \
"$srcdir/gitlab_api.sh" "/projects" -X POST \
    -d "{
    \"name\": \"$name\",
    \"import_url\": \"$import_url\",
    \"mirror\": true
}"
echo >&2

# XXX: only available in premium unfortunately
#timestamp "Configuring repo mirroring from '$import_url'"
#"$srcdir/gitlab_api.sh" "/projects/$user/$name/mirror/pull" -X POST \
#    -d "{
#    \"import_url\": \"$import_url\",
#    \"mirror\": true
#}"
