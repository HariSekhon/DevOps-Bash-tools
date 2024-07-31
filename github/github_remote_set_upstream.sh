#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-07-31 18:50:34 +0300 (Wed, 31 Jul 2024)
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
. "$srcdir/lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
In a forked GitHub repo's checkout, determine the origin of the fork using GitHub CLI and configure a git remote to the upstream

Useful to be able to easily pull updates from the original source repo
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<owner/repo>]"

help_usage "$@"

max_args 1 "$@"

check_github_origin

if [ $# -gt 0 ]; then
    upstream_owner_repo="$1"
    shift
else
    upstream_owner_repo="$(github_upstream_owner_repo || die "Not a forked repo?")"
fi

# follow the clone checkout scheme eg. https:// or ssh://
#
# this helps remote workers like me avoiding proxy / wifi hotspot restrictions using HTTPS clones instead of SSH
timestamp "Determining git base url"
echo
github_url_base="$(
    git remote -v |
    awk '/origin/ { print $2; exit }' |
    sed 's|\(.*github.com[:/]\).*|\1|'
)"

if git remote -v | grep -q '^upstream'; then
    timestamp "Git remote 'upstream' already exists, not creating"
else
    timestamp "Adding git remote 'upstream' to be able to pull directly from original source repo we are forked from"
    git remote add upstream "${github_url_base}${upstream_owner_repo}"
fi
