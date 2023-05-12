#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: PyYAML GitPython
#
#  Author: Hari Sekhon
#  Date: 2019-02-19 01:55:24 +0000 (Tue, 19 Feb 2019)
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
Translates Python pip modules to import names

Used by adjacent script python_pip_install_if_absent.sh to check if a module is available somewhere in the path by trying to import it


Reads from standard input if no args are given
"

# shellcheck disable=SC2034
usage_args="[<module1> <module2> ...]"

help_usage "$@"


mappings="$srcdir/../resources/pipreqs_mapping.txt"

if ! [ -f "$mappings" ]; then
    wget -O "$mappings" https://raw.githubusercontent.com/bndr/pipreqs/master/pipreqs/mapping
fi

sed_script="$(
    tr ':' ' ' < "$mappings" |
    while read -r import_name module_name rest; do
        if ! [[ "$import_name" =~ ^[A-Za-z0-9/_.-]+$ ]]; then
            echo "import name '$import_name' did not match expected alphanumeric regex!" >&2
            continue
        fi
        if ! [[ "$module_name" =~ ^[A-Za-z0-9_.-]+$ ]]; then
            echo "import module name '$module_name' did not match expected alphanumeric regex!" >&2
            continue
        fi
        echo "s|^$module_name$|$import_name|;"
    done
)"

if [ $# -gt 0 ]; then
    for x in "$@"; do
        if [ -f "$x" ]; then
            cat "$x"
        else
            echo "$x"
        fi
    done
else
    cat
fi |
sed 's/[>=].*$//;' |
    # these have been replaced my pipreqs mapping file
    #s/beautifulsoup4/bs4/;
    #s/PyYAML/yaml/;
    #s/GitPython/git/;
    #s/traceback2/traceback/;
sed "$sed_script" |
    # general rules:
    # - import names don't have python-* prefixes
    # - import names don't have *-python suffixes
    # - import names replace dashes with underscores
    # - psycopg2-binary -> psycopg2
sed '
    s/^python-//;
    s/-*python$//;
    s/-binary$//;
    s/-/_/g;
    s/\[.*\]//
' # |
    # generally lowercase but a couple of exceptions - these are in mappings file so we don't execute this conversion any more
#tr '[:upper:]' '[:lower:]' |
#sed '
#    s/mysqldb/MySQLdb/;
#    s/krbv/krbV/;
#'
