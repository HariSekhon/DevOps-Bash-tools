#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-20 14:50:09 +0700 (Thu, 20 Feb 2025)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Shows only file addition commits in the Git log done by you

Useful to remind yourself what parts the current Git repo you've added - for periodic reviews, reports
or even updating your CV!

Filters the Git log for your Git configured username and email address using adjacent script:

    git_log_me.sh

Passes all args through to git log so you can add additional filters eg.

    ${0##*/} --all

    ${0##*/} --oneline
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<git_log_options>]"

help_usage "$@"

"$srcdir/git_log_me.sh" --diff-filter=A "$@"
