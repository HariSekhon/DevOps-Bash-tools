#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-14 00:11:35 +0700 (Tue, 14 Jan 2025)
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
Calculate Man Years of Work for a given number of lines of code

Uses the conservative formula:

2.4 × ( ( Lines of Code / 1000 ) ^ 1.05 ) / 12

Get lines of code for a project using the cloc tool

Or for all original public repos for a given user, this script:

    ../github/github_public_lines_of_code.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<lines_of_code>"

help_usage "$@"

min_args 1 "$@"

lines_of_code="$1"

if ! is_int "$lines_of_code"; then
    die "Lines of Code given is not an integer!"
fi

kloc="$((lines_of_code / 1000))"

kloc_power="$(bc -l <<< "e(1.05 * l($kloc))")"

bc -l <<< "2.4 * $kloc_power / 12"
