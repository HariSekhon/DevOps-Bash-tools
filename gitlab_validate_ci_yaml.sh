#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 18:39:12 +0100 (Sun, 16 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://docs.gitlab.com/ee/api/lint.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Validates a given GitLab CI config via the GitLab APIv4

Example:

${0##*/} .gitlab-ci.yml


If no arg is given, will look for .gitlab-ci.yml in the current directory

"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="/path/to/.gitlab-ci.yml"

help_usage "$@"

#min_args 1 "$@"

gitlab_ci_yml=".gitlab-ci.yml"

if [ $# -gt 0 ]; then
    filename="$1"
    if ! [[ "$filename" =~ $gitlab_ci_yml$ ]]; then
        die "invalid filename given, must be called 'gitlab_ci_yml', instead got:  $filename"
    fi
elif [ -f "$gitlab_ci_yml" ]; then
    filename="$gitlab_ci_yml"
else
    usage "no filename given and no file '$gitlab_ci_yml' found in the current directory"
fi

content="$(sed 's/#.*//; /^[[:space:]]*$/d' "$filename")"

json_content="$("$srcdir/yaml2json.sh" <<< "$content")"

# escape quotes and must not have any indentations and be on one line
json_content_escaped="$(sed 's/"/\\"/g;s/^[[:space:]]*//;' <<< "$json_content" | tr -d '\n')"

# doesn't need to be authenticated
#"$srcdir/gitlab_api.sh" /ci/lint -X POST --header "Content-Type: application/json" --data "{\"content\": \"$json_content_escaped\"}" | jq -r .status
result="$(curl -sS --fail https://gitlab.com/api/v4/ci/lint -X POST --header "Content-Type: application/json" --data "{\"content\": \"$json_content_escaped\"}" | jq -r .status)"
echo "$result"
if [ "$result" != valid ]; then
    exit 1
fi
