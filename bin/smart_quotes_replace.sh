#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-03-27 22:28:37 +0800 (Thu, 27 Mar 2025)
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
Replace smart quotes with their regular counterparts using sed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<files_and_sed_options>"

help_usage "$@"

min_args 1 "$@"

# these are supposed to be unquoted quotes
# shellcheck disable=SC1111
sed "
    s/“/\"/g;
    s/”/\"/g;
    s/‘/'/g;
    s/’/'/g;
" "$@"
