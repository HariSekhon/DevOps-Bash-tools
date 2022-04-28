#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-10-06 13:17:14 +0200 (Fri, 06 Oct 2017)
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

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# NFS issues sometimes cause scripts to rewritten from vim without executable bit set, which then gets committed to git by accident

section "Finding Non Executable Scripts"

script_extensions="
sh
py
pl
rb
"

ext_regex=""
for ext in $script_extensions; do
    ext_regex="$ext_regex|\\.$ext"
done
ext_regex="(${ext_regex#|})$"

filter_is_git_committed(){
    while read -r filename; do
        pushd "$(dirname "$filename")" &>/dev/null
        set +o pipefail
        git status --porcelain "$filename" | grep -q '^??' || echo "$filename"
        set -o pipefail
        popd &>/dev/null
    done
}

filter_not_python_library(){
    while read -r filename; do
        pushd "$(dirname "$filename")" &>/dev/null
        test -f __init__.py || echo "$filename"
        popd &>/dev/null
    done
}

set +o pipefail
# -executable switch not available on Mac
# trying to build up successive -name options doesn't work and ruins the logic of find, simplify to grep
non_executable_scripts="$(
    eval find "${1:-$PWD}" -maxdepth 2 -type f -not -perm -u+x |
    grep -E "$ext_regex" |
    grep -v -e '/\.[[:alnum:]]' |
    filter_is_git_committed |
    filter_not_python_library |
    tee /dev/stderr
)"
set -o pipefail

echo
if [ -z "$non_executable_scripts" ]; then
    echo "OK: no non-executable scripts detected"
    exit 0
else
    echo 'FAILED: non-executable scripts detected!'
    exit 1
fi
