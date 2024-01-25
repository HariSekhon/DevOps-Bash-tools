#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: DevOps-Bash-tools
#  args: HariSekhon/DevOps-Bash-tools
#
#  Author: Hari Sekhon
#  Date: 2020-10-01 12:15:48 +0100 (Thu, 01 Oct 2020)
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
. "$srcdir/lib/travis.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Add a cron job to a given Travis CI repo using the Travis CI API

Since you can only have 1 cronjob per branch per repo, this overwrites any existing cron on that branch

If no repo is given, then tries to determine the repo name from the local git remote url

If the repo doesn't have a user / organization prefix, then queries
the Travis CI API for the currently authenticated username first

Args:

branch              - defaults to 'master'
interval            - defaults to 'monthly'. Options: daily, weekly, monthly
recent_dont_rerun   - boolean, defaults to 'true'. Don't run cron job if a build has occurred in the last 24 hours. Set to 0 or 'false' to disable this, any other value is taken as 'true'

Prints the JSON of the cron it just created showing all the details

Uses the adjacent travis_api.sh script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<user>/]<repo> [<branch>] [<interval>] [<recent_dont_rerun>] [<curl_options>]"

help_usage "$@"

#min_args 1 "$@"

repo="${1:-}"
branch="${2:-master}"
interval="${3:-monthly}"
recent_dont_rerun="${4:-true}"
shift || :
shift || :
shift || :
shift || :

repo="$(travis_prefix_encode_repo "$repo")"

recent_dont_rerun="${recent_dont_rerun//[[:space:]]/}"
case "$recent_dont_rerun" in
    0  | false ) recent_dont_rerun=0
                 ;;
             * ) recent_dont_rerun=1
                 ;;
esac

"$srcdir/travis_api.sh" "/repo/$repo/branch/$branch/cron" -X POST -d "cron.interval=$interval&cron.dont_run_if_recent_build_exists=$recent_dont_rerun" |
jq -r '"Created cron for repo \"" + .repository.slug + "\" on branch \"" + .branch.name + "\" at interval \"" + .interval +"\""' |
timestamp "$(cat)"
