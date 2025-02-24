#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-24 15:08:43 +0700 (Mon, 24 Feb 2025)
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
Runs Markdownlint mdl command and prefixes the spaces count to each offending line of MD005
(inconsistent list indentations)

Workaround for:

    https://github.com/DavidAnson/markdownlint/issues/1514

Tested on MarkdownLint 0.13.0
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<markdownlint_args_such_as_filenames>"

help_usage "$@"

mdl "$@" |
awk '/: MD005/{print $1}' |
sed 's/:/ /g' |
while read -r filename line_number; do
    sed -n "${line_number} p" "$filename" |
    awk '{print length($0) - length(substr($0, match($0, /[^ ]/)))}' |
    tr -d '\n'
    echo -n ":$filename:$line_number:"
    sed -n "${line_number} p" "$filename"
done
