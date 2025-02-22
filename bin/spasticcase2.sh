#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-02-17 22:35:54 +0700 (Mon, 17 Feb 2025)
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
Change input to sPaStIcCaSe for replying to people who don't understand economics, demographics or logic

Accepts a string, file or standard input

Outputs to stderr and copies to clipboard for convenience
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<string_or_file>]"

help_usage "$@"

capitalize_alternate(){
    awk '{
        for (i = 1; i <= length($0); i++) {
            c = substr($0, i, 1);
            if (i % 2 == 0) {
                printf toupper(c);
            } else {
                printf tolower(c);
            }
        }
        print "";
    }'
}

if [ $# -eq 0 ]; then
    log "Reading from standard input"
    cat "$@"
else
    if [[ "$1" =~ ^.?/ ]] || [ -f "$1" ]; then
        log "Reading from files: $*"
        cat "$@"
    else
        echo "$*"
    fi
fi |
capitalize_alternate |
tee >("$srcdir/copy_to_clipboard.sh") /dev/stdout
# copies to clipboard and also sends to stdout to allow further pipeline processing
