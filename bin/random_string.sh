#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-24 00:45:44 +0100 (Wed, 24 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Generates a random alphanumeric string of the given length
#
# pwgen is also a good option, but may not always be installed, hence this is more portable

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Prints a random alphanumeric string of the given character length
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<num_chars>"

help_usage "$@"

max_args 1 "$@"

len="${1:-32}"

if ! is_int "$len"; then
    usage "Invalid non-integer string length given as first argument"
fi

# fixes illegal byte error in tr / sed etc
export LC_ALL=C

#tr -duc 'A-Za-z0-9' < /dev/urandom |
tr -duc '[:alnum:]' < /dev/urandom |
#fold -w "$len" | head -n1
head -c "$len" || :  # head returns error code 141 but succeeds
