#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-08 13:15:00 +0700 (Wed, 08 Jan 2025)
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
Runs each binary of the given name found in \$PATH with the args given

Useful to find all the installed versions of a program in different paths eg. ~/bin/ vs /usr/local/bin/

Eg.

    ${0##*/} terraform --version
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="binary <args>"

help_usage "$@"

min_args 2 "$@"

binary="$1"

shift || :

# sed used to regularize /path/to/bin and /path/to//bin caused by multiple path additions some with or without trailing
# slashes leading to double slashes in the path. By regularizing them we are then able to dedupe them properly
#
binaries="$(which -a "$binary" | sed 's|//*|/|g' | sort -u)"

while read -r binary; do
    echo "# ============================================================================ #" >&2
    echo "# $binary" >&2
    echo "# ============================================================================ #" >&2
    echo >&2
    "$binary" "$@"
    echo >&2
    echo >&2
done <<< "$binaries"
