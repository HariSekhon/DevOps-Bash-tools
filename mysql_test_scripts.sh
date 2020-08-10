#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC2028
#
#  Author: Hari Sekhon
#  Date: 2020-08-09 10:42:23 +0100 (Sun, 09 Aug 2020)
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

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

mysql_versions="5.5 5.6 5.7 8.0 latest"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs all of the scripts given as arguments against multiple MySQL versions using docker

Uses mysqld.sh to boot a mysql docker environment and pipe source statements in to the container

Sources each script in MySQL in the order given

Runs against a list of MySQL versions from the first of the following conditions:

- If \$MYSQL_VERSIONS environment variable is set, then only tests against those versions in the order given
- If \$GET_DOCKER_TAGS is set and dockerhub_show_tags.py is found in the \$PATH (from DevOps Python tools repo), then uses it to fetch the latest live list of version tags available from the dockerhub API, reordering by newest first
- Falls back to the following pre-set list of versions, reordering by newest first:

$(tr ' ' '\n' <<< "$mysql_versions")
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="script1.sql [script2.sql ...]"

help_usage "$@"

min_args 1 "$@"

for sql in "$@"; do
    [ -f "$sql" ] || die "ERROR: file not found: $sql"
done

get_mysql_versions(){
    if [ -n "${GET_DOCKER_TAGS:-}" ]; then
        echo "checking if dockerhub_show_tags.py is available:" >&2
        echo
        if type -P dockerhub_show_tags.py 2>/dev/null; then
            echo
            echo "dockerhub_show_tags.py found, executing to get latest list of MySQL docker version tags" >&2
            echo
            mysql_versions="$(dockerhub_show_tags.py mysql |
                                grep -Eo -e '[[:space:]][[:digit:]]{1,2}\.[[:digit:]]' \
                                         -e '^[[:space:]*latest[[:space:]]*$' |
                                sed 's/[[:space:]]//g' |
                                sort -u -t. -k1n -k2n)"
            echo "found MySQL versions:" >&2
            echo "$mysql_versions"
            return
        fi
    fi
    echo "using default list of MySQL versions to test against:" >&2
    echo "$mysql_versions"
}

if [ -n "${MYSQL_VERSIONS:-}" ]; then
    mysql_versions="${MYSQL_VERSIONS//,/ }"
    echo "using given MySQL versions:"
else
    mysql_versions="$(get_mysql_versions | tr ' ' '\n' | tail -r)"
fi

tr ' ' '\n' <<< "$mysql_versions"
echo

for version in $mysql_versions; do
    hr
    echo "Executing scripts against MySQL version '$version'": >&2
    echo >&2
    {
    echo 'SELECT VERSION();'
    for sql in "$@"; do
        # comes out first, not between scripts
        #echo '\! printf "================================================================================\n"'
        # no effect
        #echo
        # comes out first instead of with scripts
        #echo "\\! printf '\nscript %s:' '$sql'"
        echo "select '$sql' as script;"
        # instead of dealing with pathing issues, prefixing /pwd or depending on the scripts being in the sql/ directory
        #echo "source $sql"
        cat "$sql"
        #echo "\\! printf '\n\n'"
    done
    } |
    # need docker run non-interactive to avoid tty errors
    # forcing mysql shell --table output as though interactive
    DOCKER_NON_INTERACTIVE=1 \
    MYSQL_OPTS="--table" \
    "$srcdir/mysqld.sh" "$version"
    echo
    echo
done
