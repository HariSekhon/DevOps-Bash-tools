#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-05-07 16:28:58 +0100 (Fri, 07 May 2021)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Finds all Python modules installed in a script and installs them if not already present

Uses adjacent scripts:

    python_translate_import_to_pip.sh
    python_pip_install_if_absent.sh


Will break on custom local modules since they won't be found on PyPI, use --exclude <regex> to avoid that. Regex is in ERE format

Eg.
    ${0##*/} *.py --exclude harisekhon  # excludes my personal local library which is not on PyPI


If you supply .pyc or .pyo filenames, it will infer to .py instead. This is useful if calling from a Makefile looking for .pyc or .pyo dynamic targets
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<script1.py> [<script2.py> <script3.py>]"

help_usage "$@"

min_args 1 "$@"

scripts=()
exclude_regex=""

until [ $# -lt 1 ]; do
    case "$1" in
        -e|--exclude)   exclude_regex="${2:-}"
                        shift || :
                        ;;
                  -*)   usage
                        ;;
                    *)  if [[ "$1" =~ \.py[co] ]]; then
                            filename="$1"
                            filename="${filename%.pyc}"
                            filename="${filename%.pyo}"
                            filename="$filename.py"
                            scripts+=("$filename")
                        else
                            scripts+=("$1")
                        fi
                        ;;
    esac
    shift || :
done

if [ ${#scripts[@]} -eq 0 ]; then
    usage
fi

pip_modules_import="$(
    grep -Eh '^[[:space:]]*import[[:space:]]' "${scripts[@]}" |
    awk '{print $2}' |
    tr -d '\r' |
    sort -u
)"
pip_modules_from_import="$(
    grep -Eho '^[[:space:]]*from[[:space:]][^[[:space:]_]+[[:space:]]+import[[:space:]]+[^[:space:]]+$' "${scripts[@]}" |
    sed 's/^[[:space:]]*from[[:space:]]*//; s/[[:space:]][[:space:]]*import[[:space:]].*$//' |
    sort -u
)"

pip_modules="$(
    sort -u <<-EOF |
    $pip_modules_import
    $pip_modules_from_import
EOF
    if [ -n "$exclude_regex" ]; then
        grep -Ev "$exclude_regex" || :
    else
        cat
    fi
)"

pip_modules="$("$srcdir/python_translate_import_to_module.sh" <<< "$pip_modules")"

"$srcdir/python_pip_install_if_absent.sh" <<< "$pip_modules"
