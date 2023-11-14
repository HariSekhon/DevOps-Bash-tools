#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-05-08 23:46:32 +0100 (Mon, 08 May 2023)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Parses shell scripts to find any references to srcdir/path/to/files.sh that are not found from the \$PWD of the script

Written to find broken srcdir references after huge repo reorganization
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="arg [<options>]"

help_usage "$@"

section "Check SrcDir References"

trap_cmd "echo 'FAILED!'"

git grep -lE 'srcdir/.+\.sh' |
grep -v '^\.bash\.d/' |
grep -v 'check_bash_references.sh' |
while read -r scriptpath; do
    pushd "$(dirname "$scriptpath")" >/dev/null
    srcdirpaths="$(
        { grep -v -e ' -x ' -e ' -f ' "${scriptpath##*/}" || : ; } |
        { grep -Eo '^[^#]*\$srcdir/[^"'"'"'[:space:]]+.sh' || : ; } |
        { grep -Eo -e 'srcdir/[^"'\''[:space:]]+\.sh' -e 'srcdir/[^"'\''[:space:]]*bashrc' || : ; } |
        sed 's|^srcdir/||'
    )"
    for srcdirpath in $srcdirpaths; do
        srcdirpath2="$(readlink -f "$srcdirpath" || :)"
        if ! test -f "$srcdirpath2"; then
            echo "$scriptpath"
            timestamp "broken srcdir path: $srcdirpath"
        fi
    done |
    sort -u |
    while read -r scriptpath; do
        timestamp "broken scrdir references found in: $scriptpath"
        exit 1
    done
    #while read -r scriptpath; do
    #    echo "$scriptpath:"
    #    echo
    #    grep -E 'srcdir/.+\.sh' "${scriptpath##*/}"
    #    echo
    #    echo
    #    exit 1
    #done
    popd >/dev/null
done

untrap
echo "All srcdir references checked: OK"
echo
echo
