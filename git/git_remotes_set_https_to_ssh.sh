#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-06 10:47:18 +0100 (Tue, 06 Oct 2020)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Changes all of the current repo's remote URLs from https:// to git@ (SSH)

Has some extra rules for conversion to Azure DevOps ssh path format since this differs from standard GitHub / GitLab / Bitbucket type paths
"

help_usage "$@"

topdir="$(git_root)"

cd "$topdir"

cp -iv -- .git/config ".git/config.$(date +%F_%H%M%S).bak"

# XXX: only replace first / with : since we're setting to git@ prefix without ssh:// prefix - if ssh://git@ then it uses slashes throughout
perl -pi -e 's/(https:\/\/[^\/]+)\//\1:/;
             s/https:\/\/(.+\@)?/git\@/;
             ' .git/config

azure_devops_url="$(grep -m1 '^[[:space:]]*url[[:space:]]*=[[:space:]]*.*dev.azure.com' .git/config | sed 's/.*url[[:space:]]*=[[:space:]]*//; s/[[:space:]]*$//' || :)"

if [ -n "$azure_devops_url" ]; then
    azure_devops_url2="$(git_to_azure_url "$azure_devops_url")"

    sed -i.bak "s|$azure_devops_url|$azure_devops_url2|" .git/config
fi

echo >&2
git remotes -v
