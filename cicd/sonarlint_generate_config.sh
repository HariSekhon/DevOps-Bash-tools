#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-25 22:39:30 +0700 (Tue, 25 Feb 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates the .sonarlint/connectedMode.json config at the root of the Git repo
from the sonar-project.properties file
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<path/to/sonar-project.properties>]"

help_usage "$@"

max_args 1 "$@"

sonar_project_properties="${1:-sonar-project.properties}"

git_root="$(git_root)"

timestamp "Switching to Git root: $git_root"
echo
cd "$git_root"

timestamp "Parsing $PWD/$sonar_project_properties"
org="$(awk -F= '/^[[:space:]]*sonar.organization/{print $2}' "$sonar_project_properties" | sed 's/[[:space:]]//g')"
project_key="$(awk -F= '/^[[:space:]]*sonar.projectKey/{print $2}' "$sonar_project_properties" | sed 's/[[:space:]]//g')"

mkdir -p -v .sonarlint

sonarlint_config="$PWD/.sonarlint/connectedMode.json"

timestamp "Writing to $sonarlint_config"
cat <<EOF | tee "$sonarlint_config"
{
    "sonarCloudOrganization": "$org",
    "projectKey": "$project_key"
}
EOF
