#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-06 10:47:18 +0100 (Tue, 06 Oct 2020)
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

# shellcheck disable=SC1090
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Changes all the current repo's .git/config URLs from https:// to git@ (SSH)
"

help_usage "$@"

topdir="$(git_root)"

cd "$topdir"

cp -iv .git/config ".git/config.$(date +%F_%H%M%S).bak"

perl -pi -e 's/(https:\/\/[^\/]+)\//\1:/; s/https:\/\/(.+@)?/git@/' .git/config
