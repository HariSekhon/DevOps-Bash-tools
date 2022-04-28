#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-27 11:49:47 +0000 (Wed, 27 Feb 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Script to find duplicate Python Pip / PyPI module requirements across files

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_args="[<pip_requirements_files>]"

for x in "$@"; do
    case "$x" in
    -h|--help)  usage
                ;;
    esac
done

found=0

if [ -n "$*" ]; then
    requirements_files="$*"
else
    requirements_files="$(find . -maxdepth 2 -name requirements.txt)"
    if [ -z "$requirements_files" ]; then
        usage "No requirements files found, please specify explicit path to requirements.txt"
    fi
fi

# need word splitting for different files
# shellcheck disable=SC2086
sed 's/#.*//;
     s/[<>=].*//;
     s/^[[:space:]]*//;
     s/[[:space:]]*$//;
     /^[[:space:]]*$/d;' $requirements_files |
sort |
uniq -d |
while read -r module ; do
    # need word splitting for different files
    # shellcheck disable=SC2086
    grep "^${module}[<>=]" $requirements_files
    ((found + 1))
done

if [ $found -gt 0 ]; then
    exit 1
fi
