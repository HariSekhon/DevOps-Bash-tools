#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019-09-18
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Fetches the GitHub user's public SSH key from the GitHub API
#
# Uses $GITHUB_USER or $USER as the expected GitHub user

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [[ "$USER" =~ hari|sekhon ]]; then
    GITHUB_USER="${GITHUB_USER:-harisekhon}"
else
    GITHUB_USER="${GITHUB_USER:-$USER}"
fi

echo "# Fetching SSH Public Key(s) from GitHub for account:  $GITHUB_USER" >&2
echo "#" >&2
curl -s "https://api.github.com/users/$GITHUB_USER/keys" |
jq -r '.[].key'
