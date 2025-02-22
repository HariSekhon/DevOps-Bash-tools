#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-16 19:34:25 +0100 (Sun, 16 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

yamls="$(find "${1:-.}" -name .gitlab-ci.yml)"

if [ -z "$yamls" ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

section "GitLab CI Yaml Lint Check"

if [ -z "${GITLAB_TOKEN:-}" ]; then
    echo "WARNING: \$GITLAB_TOKEN not found in environment and this API endpoint now requires authentication, skipping..." >&2
    exit 0
fi

start_time="$(start_timer)"

while read -r yaml; do
    printf 'Validating %s:\t' "$yaml"
    "$srcdir/../gitlab/gitlab_validate_ci_yaml.sh" "$yaml"
done <<< "$yamls"

time_taken "$start_time"
section2 "GitLab CI yaml validation succeeded"
echo
