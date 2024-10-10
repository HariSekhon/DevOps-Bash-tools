#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-11 01:35:54 +0300 (Fri, 11 Oct 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://github.com/sqlfluff/sqlfluff

# https://docs.sqlfluff.com/en/stable/reference/cli.html

# https://docs.sqlfluff.com/en/stable/reference/dialects.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/sql.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Recursively iterates all SQL code files found in the given or current directory and runs SQLFluff linter against them,
inferring the different SQL dialects from each path/filename/extension

If you don't have a mixed SQL tree or repo to lint then you could just do this as a single call to SQLFluff like so

    sqlfluff lint --dialect postgres .

Useful to call in CI/CD or precommit linting
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir> <sqlfluff_options>]"

help_usage "$@"

dir="${1:-.}"
shift || :

exitcode=0

section "SQLFluff"

if ! type -P sqlfluff &>/dev/null; then
    timestamp "SQLFluff not installed, attempting to install it now..."
    "$srcdir/../packages/install_package.sh" sqlfluff ||
    pip install sqlfluff
    echo
fi

echo
sqlfluff --version
echo

if is_CI; then
    export VERBOSE=1
fi

while read -r path; do
    dialect="$(infer_sql_dialect_from_path "$path" || { echo "Falling back to ANSI dialect" >& 2; echo "ansi"; } )"
    opts=(--dialect "$dialect")
    if is_CI; then
        opts+=(--nocolor)
    fi
    timestamp "SQLFluffing: $path"
    log "Cmd: sqlfluff lint ${opts[*]} $path"
    if ! sqlfluff lint "${opts[@]}" "$path"; then
        exitcode=1
        echo
    fi
done < <(find "$dir" -iname '*.sql' -type f)

msg="completed successfully"
if [ "$exitcode" != 0 ]; then
    msg="found errors!"
fi
timestamp "SQLFluffing $msg"
echo
hr
exit "$exitcode"
