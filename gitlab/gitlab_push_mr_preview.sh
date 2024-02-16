#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-15 11:16:44 +0100 (Fri, 15 Jul 2022)
#
#  https://gitlab.com/HariSekhon/DevOps-Bash-tools
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
. "$srcdir/lib/gitlab.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Pushes the current branch to GitLab origin, setting upstream branch, then opens a Pull Request preview from current to default branch

Assumes that GitLab is the remote origin, and checks for this for safety


Requires GitLab CLI to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

max_args 2 "$@"

check_gitlab_origin

current_branch="$(current_branch)"

git push --set-upstream origin "$current_branch"

glab mr create --web --fill
