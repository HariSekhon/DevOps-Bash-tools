#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-12-06 18:03:20 +0000 (Sun, 06 Dec 2020)
#
#  https://github.com/HariSekhon/bash-tools
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
Creates a TeamCity GitHub OAuth provider configuration in the Root project

Requires TEAMCITY_GITHUB_CLIENT_ID and TEAMCITY_GITHUB_CLIENT_SECRET environment variables to be declared

For TeamCity connectivity and authentication see adjacent script teamcity_api.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

check_env_defined "TEAMCITY_GITHUB_CLIENT_ID"
check_env_defined "TEAMCITY_GITHUB_CLIENT_SECRET"

if "$srcdir/teamcity_api.sh" /projects/_Root |
   jq -r '.projectFeatures.projectFeature[].properties.property[] | select(.name == "displayName") | .value' |
   grep -qi '^GitHub.com$'; then
    timestamp "TeamCity GitHub OAuth provider in Root project already exists, skipping..."
    exit 0
fi

timestamp "Creating TeamCity GitHub OAuth provider in Root project"
"$srcdir/teamcity_api.sh" "/projects/_Root/projectFeatures" -X POST -d @<(cat <<EOF
    {
      "id": "GitHub",
      "type": "OAuthProvider",
      "properties": {
        "property": [
          {
            "name": "providerType",
            "value": "GitHub"
          },
          {
            "name": "displayName",
            "value": "GitHub.com"
          },
          {
            "name": "gitHubUrl",
            "value": "https://github.com/"
          },
          {
            "name": "defaultTokenScope",
            "value": "public_repo,repo,repo:status,write:repo_hook"
          },
          {
            "name": "clientId",
            "value": "$TEAMCITY_GITHUB_CLIENT_ID"
          },
          {
            "name": "clientSecret",
            "value": "$TEAMCITY_GITHUB_CLIENT_SECRET"
          }
        ]
      }
    }
EOF
)
