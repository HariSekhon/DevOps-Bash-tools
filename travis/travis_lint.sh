#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-01 00:19:22 +0100 (Thu, 01 Oct 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Lints the local .travis.yml using the Travis CI API

For production CI see instead the 'travis' gem and the adjacent script 'check_travis_yml.sh'

Uses the adjacent travis_api.sh script
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<.travis.yml>"

help_usage "$@"

#min_args 1 "$@"

if [ $# -eq 1 ]; then
    travis_yml="$1"
elif [ -f .travis.yml ]; then
    travis_yml=.travis.yml
else
    usage
fi

"$srcdir/travis_api.sh" "/lint" -X POST -d @"$travis_yml"
