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

# Script to find unused Python Pip / PyPI modules in the current git directory tree

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh disable=SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_args="[<requirements.txt>]"

for x in "$@"; do
    case "$x" in
    -h|--help)  usage
                ;;
    esac
done

if [ $# -gt 0 ]; then
    requirements_files=("$@")
else
    # might be more confusing in pytools to find unused modules in subdirs like pylib, so just stick to local
    #requirements_files="$(find . -name requirements.txt)"
    requirements_files=("requirements.txt")
    if [ "${#requirements_files[@]}" = 0 ]; then
        usage "No requirements files found, please specify explicit path to requirements.txt"
    fi
fi

found=0

pip_modules="$(
    sed 's/#.*//;
     s/[<>=].*//;
     s/^[[:space:]]*//;
     s/[[:space:]]*$//;
     /^[[:space:]]*$/d;' "${requirements_files[@]}" |
     sort -u |
     "$srcdir/python_translate_module_to_import.sh"
)"

while read -r module; do
        # grep -R is sloooow by comparison to git grep
        #grep -R "import[[:space:]]\\+$module\\|from[[:space:]]\\+$module[[:space:]]\\+import[[:space:]]\\+" . |
    if ! \
        git grep "import[[:space:]]\\+$module\\|from[[:space:]]\\+$module\\([[:alnum:]\\.]\\+\\)\\?[[:space:]]\\+import[[:space:]]\\+" |
        grep -v requirements.txt |
        grep -q .; then
            echo "$module"
            ((found + 1))
    fi
done <<< "$pip_modules"

if [ $found -gt 0 ]; then
    exit 1
fi
