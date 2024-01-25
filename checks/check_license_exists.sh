#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-02-08 11:10:28 +0000 (Tue, 08 Feb 2022)
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
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Checks that there is a LICENSE or LICENSE.txt at the top of a git repo and that it is not empty
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

section2 'License file check'

if ! git_root="$(git_root)"; then
    echo 'Not a git repository, skipping...'
    echo
    exit 0
fi

cd "$git_root"

for x in LICENSE LICENSE.txt; do
    if [ -s "$x" ]; then
        echo "OK: $x file found"
        exit 0
    elif [ -f "$x" ]; then
        echo "WARNING: $x file found but it is empty! "
        exit 1
    fi
done

echo 'WARNING: LICENSE file not found!'
exit 1
