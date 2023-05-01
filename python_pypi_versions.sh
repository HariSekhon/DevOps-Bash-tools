#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: superset
#
#  Author: Hari Sekhon
#  Date: 2020-07-19 15:58:35 +0100 (Sun, 19 Jul 2020)
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

# shellcheck disable=SC2034
usage_description="
Lists the versions of a Python package on PyPI
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<package_name> [<curl_options>]"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

help_usage "$@"

min_args 1 "$@"

package="$1"

shift || :

response="$(curl -sSL "https://pypi.org/pypi/$package/json" "$@")"

if ! jq -r '.releases | keys | .[]' <<< "$response"; then
    cat >&2 <<EOF
$response
EOF
    exit 1
fi
