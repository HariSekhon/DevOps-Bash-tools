#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-03-15 03:01:21 +0800 (Sat, 15 Mar 2025)
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
Configures APT lock timeouts so APT install commands don't just error out

Timeout seconds defaults to 1200 if not specified

Creates or appends to file:

    /etc/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<seconds>]"

help_usage "$@"

max_args 1 "$@"

seconds="${1:-1200}"

setting="DPkg::Lock::Timeout"

line="$setting \"$seconds\";"

file="/etc/apt/apt.conf.d/99timeout"

if grep -q "^[[:space:]]*${setting}[[:space:]]" "$file" 2>/dev/null; then
    sed -i "s/[[:space:]]*$setting.*/$line/" "$file"
else
    echo "$line" >> "$file"
fi
