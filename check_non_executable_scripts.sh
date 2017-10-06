#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-10-06 13:17:14 +0200 (Fri, 06 Oct 2017)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$srcdir/utils.sh"

# NFS issues sometimes cause scripts to rewritten from vim without executable bit set, which then gets committed to git by accident

section "Find Non Executable Scripts"

script_extensions="
sh
py
pl
rb
"

name_opt=""
for ext in $script_extensions; do
    name_opt="$name_opt -o -name '*.$ext'"
done
name_opt="${name_opt# -o }"

# -executable switch not available on Mac
if ! is_linux; then
    echo "Non-Linux system detected, skipping as find perm behaviour is broken on Mac"
    return 0 &>/dev/null || :
    exit 0
fi

non_executable_scripts="$(eval find "${1:-.}" -maxdepth 2 -not -perm -500 -type f $name_opt)"

if [ -n "$non_executable_scripts" ]; then
    echo
    echo 'Non-executable scripts detected!'
    exit 1
fi
