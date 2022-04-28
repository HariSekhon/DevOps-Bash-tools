#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2018-08-09 21:34:03 +0100 (Thu, 09 Aug 2018)
#
#  https://github.com/HariSekhon/pylib
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

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

tld_files="
tlds-alpha-by-domain.txt
custom_tlds.txt
"

section "Checking TLDs for suspect chars"

start_time="$(start_timer)"

files="${*:-}"
if [ -z "$files" ]; then
    for x in $tld_files; do
        files="$files $(find . -iname "$x")"
    done
fi

set +e
for x in $files; do
    #isExcluded "$x" && continue
    echo "checking $x"
    if sed 's/#.*//;/^[[:space:]]$/d;s/[[:alnum:]-]//g' "$x" | grep -o '.'; then
        echo
        echo "ERROR: Invalid chars detected in TLD file $x!! "
    fi
done

time_taken "$start_time"
section2 "Finished checking TLDs for suspect chars"
