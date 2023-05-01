#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC2028
#
#  Author: Hari Sekhon
#  Date: 2020-08-09 10:42:23 +0100 (Sun, 09 Aug 2020)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/dbshell.sh"

mysql_versions="
5.5
5.6
5.7
8.0
latest
"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs all of the scripts given as arguments against multiple MySQL versions using docker

Uses mysqld.sh to boot a mysql docker environment and pipe source statements in to the container

Sources each script in MySQL in the order given

Runs against a list of MySQL versions from the first of the following conditions:

- If \$MYSQL_VERSIONS environment variable is set, then only tests against those versions in the order given, space or comma separated, with 'x' used as a wildcard (eg. '5.x , 8.x')
- If \$GET_DOCKER_TAGS is set and dockerhub_show_tags.py is found in the \$PATH (from DevOps Python tools repo), then uses it to fetch the latest live list of version tags available from the dockerhub API, reordering by newest first
- Falls back to the following pre-set list of versions, reordering by newest first:

$(tr ' ' '\n' <<< "$mysql_versions" | grep -v '^[[:space:]]*$')

If a script has a headers such as:

-- Requires MySQL N.N (same as >=)
-- Requires MySQL >= N.N
-- Requires MySQL >  N.N
-- Requires MySQL <= N.N
-- Requires MySQL <  N.N

then will only run that script on the specified versions of MySQL

This is for convenience so you can test a whole repository such as my SQL-scripts repo just by running against all scripts and have this code figure out the combinations of scripts to run vs versions, eg:

${0##*/} mysql_*.sql

If no script files are given as arguments, then searches \$PWD for scripts named in the formats:

mysql*.sql
*.mysql


Tested on MySQL 5.5, 5.6, 5.7, 8.0
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="script1.sql [script2.sql ...]"

help_usage "$@"

#min_args 1 "$@"

export MYSQL_CONTAINER_NAME="${MYSQL_CONTAINER_NAME:-mysql-test-scripts}"

if [ $# -gt 0 ]; then
    scripts=("$@")
else
    shopt -s nullglob
    scripts=(mysql*.sql *.mysql)
fi

if [ ${#scripts[@]} -lt 1 ]; then
    usage "no scripts given and none found in current working directory matching the patterns: mysql*.sql / *.mysql"
fi

for sql_file in "${scripts[@]}"; do
    [ -f "$sql_file" ] || die "ERROR: file not found: $sql_file"
done

echo "Testing ${#scripts[@]} MySQL scripts:"
echo
for sql_file in "${scripts[@]}"; do
    echo "$sql_file"
done
echo

get_mysql_versions(){
    if [ -n "${GET_DOCKER_TAGS:-}" ]; then
        echo "checking if dockerhub_show_tags.py is available:" >&2
        echo >&2
        if type -P dockerhub_show_tags.py 2>/dev/null; then
            echo
            echo "dockerhub_show_tags.py found, executing to get latest list of MySQL docker version tags" >&2
            echo >&2
            mysql_versions="$(dockerhub_show_tags.py mysql |
                                grep -Eo -e '[[:space:]][[:digit:]]{1,2}\.[[:digit:]]' \
                                         -e '^[[:space:]*latest[[:space:]]*$' |
                                sed 's/[[:space:]]//g' |
                                sort -u -t. -k1n -k2n)"
            echo "found MySQL versions:" >&2
            echo >&2
            echo "$mysql_versions"
            return
        fi
    fi
    echo "$mysql_versions" |
    tr ' ' '\n' |
    grep -v '^[[:space:]]*$' |
    if is_CI; then
        echo "CI detected - using randomized sample of MySQL versions to test against:" >&2
        {
        shuf | head -n 1
        echo 5.5  # most problematic / incompatible versions should always be tested
        echo 5.6
        echo latest
        } | sort -unr -t. -k1,2
    else
        echo "using default list of MySQL versions to test against:" >&2
        cat
    fi
    echo >&2
}

if [ -n "${MYSQL_VERSIONS:-}" ]; then
    versions=""
    MYSQL_VERSIONS="${MYSQL_VERSIONS//,/ }"
    for version in $MYSQL_VERSIONS; do
        if [[ "$version" =~ x ]]; then
            versions+=" $(grep "${version//x/.*}" <<< "$mysql_versions" |
                          sort -u -t. -k1n -k2 |
                          tac ||
                          die "version '$version' not found")"
        else
            versions+=" $version"
        fi
    done
    mysql_versions="$(tr ' ' '\n' <<< "$versions" | grep -v '^[[:space:]]*$')"
    echo "using given MySQL versions:"
else
    mysql_versions="$(get_mysql_versions | tac)"
fi

echo "$mysql_versions"
echo

for version in $mysql_versions; do
    hr
    echo "Executing scripts against MySQL version '$version'": >&2
    echo >&2
    {
    echo 'SELECT VERSION();'
    for sql_file in "${scripts[@]}"; do
        if skip_min_version "MySQL" "$version" "$sql_file"; then
            continue
        fi
        if skip_max_version "MySQL" "$version" "$sql_file"; then
            continue
        fi
        # comes out first, not between scripts
        #echo '\! printf "================================================================================\n"'
        # no effect
        #echo
        # comes out first instead of with scripts
        #echo "\\! printf '\nscript %s:' '$sql_file'"
        echo "select '$sql_file' as script;"
        # instead of dealing with pathing issues, prefixing /pwd or depending on the scripts being in the sql/ directory
        # just cat them in to the shell instead as it's more portable
        #echo "source $sql_file"
        cat "$sql_file"
        #echo "\\! printf '\n\n'"
    done
    } |
    # forcing mysql shell --table output as though interactive
    MYSQL_OPTS="--table" \
    command time \
    "$srcdir/mysqld.sh" "$version" --restart
    echo >&2
    timestamp "Succeeded testing ${#scripts[@]} scripts for MySQL $version"
    echo >&2
    echo >&2
done
echo >&2
echo >&2
timestamp "All MySQL tests passed for all scripts on all versions:  $(tac <<< "$mysql_versions" | tr '\n' ' ')"
