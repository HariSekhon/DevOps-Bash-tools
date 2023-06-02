#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-06-03 00:14:52 +0100 (Sat, 03 Jun 2023)
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
. "$srcdir/lib/bitbucket.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Enables all Bitbucket CI/CD pipelines via the BitBucket API

Uses the adjacent script bitbucket_api.sh, see there for authentication details

\$CURL_OPTS can be set to provide extra arguments to curl


If you get an error it's possible you don't have the right token permissions.
You can generate a new token with the right permissions here:

    https://bitbucket.org/account/settings/app-passwords/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

"$srcdir/bitbucket_foreach_repo.sh" "
    '$srcdir/bitbucket_repo_enable_pipeline.sh' '{repo}'
"
