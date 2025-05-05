#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: 'Hacking the Planet!'
#
#  Author: Hari Sekhon
#  Date: 2025-05-05 14:35:55 +0300 (Mon, 05 May 2025)
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
Change input to Hackercase => h4cK3Rc453 for l33t speak

Accepts a string, file or standard input

Outputs to stderr and copies to clipboard for convenience
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<string_or_file>]"

help_usage "$@"


if [ $# -eq 0 ]; then
    log "Reading from standard input"
    cat "$*"
else
    if [[ "$1" =~ ^.?/ ]] || [ -f "$1" ]; then
        log "Reading from files: $*"
        cat "$@"
    else
        echo "$*"
    fi
fi |
spasticcase.sh |
sed '
    s/a/4/gi;
    s/b/8/gi;
    s/e/3/gi;
    s/i/1/gi;
    s/o/0/gi;
    # these reduce readability
    #s/g/6/gi;
    #s/s/5/gi;
    #s/t/7/gi;
' |
tee >("$srcdir/copy_to_clipboard.sh")
# copies to clipboard and also sends to stdout to allow further pipeline processing
