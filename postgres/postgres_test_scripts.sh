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

postgres_versions="
8.4
9.0
9.1
9.2
9.3
9.4
9.5
9.6
10.0
10.1
10.2
10.3
10.4
10.5
10.6
10.7
10.8
10.9
11.0
11.1
11.2
11.3
11.4
11.5
11.6
11.7
11.8
12.0
12.1
12.2
12.3
12.4
13.0
latest
"

# shellcheck disable=SC2034,SC2154
usage_description="
Runs all of the scripts given as arguments against multiple PostgreSQL versions using docker

Uses postgres.sh to boot a PostgreSQL docker environment and pipe source statements in to the container

Sources each script in PostgreSQL in the order given

Runs against a list of PostgreSQL versions from the first of the following conditions:

- If \$POSTGRES_VERSIONS environment variable is set, then only tests against those versions in the order given, space or comma separated, with 'x' used as a wildcard (eg. '10.x , 11.x , 12.x')
- If \$GET_DOCKER_TAGS is set and dockerhub_show_tags.py is found in the \$PATH (from DevOps Python tools repo), then uses it to fetch the latest live list of version tags available from the dockerhub API, reordering by newest first
- Falls back to the following pre-set list of versions, reordering by newest first:

$(tr ' ' '\n' <<< "$postgres_versions" | grep -v '^[[:space:]]*$')

If a script has a headers such as:

-- Requires PostgreSQL N.N (same as >=)
-- Requires PostgreSQL >= N.N
-- Requires PostgreSQL >  N.N
-- Requires PostgreSQL <= N.N
-- Requires PostgreSQL <  N.N

then will only run that script on the specified versions of PostgreSQL

This is for convenience so you can test a whole repository such as my SQL-scripts repo just by running against all scripts and have this code figure out the combinations of scripts to run vs versions, eg:

${0##*/} postgres_*.sql

If no script files are given as arguments, then searches \$PWD for scripts named in the formats:

postgres*.sql
*.psql


Tested on PostgreSQL 8.4, 9.x, 10.x, 11.x, 12.x, 13.0
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="script1.sql [script2.sql ...]"

help_usage "$@"

#min_args 1 "$@"

export POSTGRES_CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:-postgres-test-scripts}"

if [ $# -gt 0 ]; then
    scripts=("$@")
else
    shopt -s nullglob
    scripts=(postgres*.sql *.psql)
fi

if [ ${#scripts[@]} -lt 1 ]; then
    usage "no scripts given and none found in current working directory matching the patterns: postgres*.sql / *.psql"
fi

for sql_file in "${scripts[@]}"; do
    [ -f "$sql_file" ] || die "ERROR: file not found: $sql_file"
done

echo "Testing ${#scripts[@]} PostgreSQL scripts:"
echo
for sql_file in "${scripts[@]}"; do
    echo "$sql_file"
done
echo

get_postgres_versions(){
    if [ -n "${GET_DOCKER_TAGS:-}" ]; then
        echo "checking if dockerhub_show_tags.py is available:" >&2
        echo >&2
        if type -P dockerhub_show_tags.py 2>/dev/null; then
            echo >&2
            echo "dockerhub_show_tags.py found, executing to get latest list of PostgreSQL docker version tags" >&2
            echo >&2
            postgres_versions="$(dockerhub_show_tags.py postgres |
                                grep -Eo '[[:space:]][[:digit:]]{1,2}\.[[:digit:]]' -e '^[[:space:]*latest[[:space:]]*$' |
                                sed 's/[[:space:]]//g' |
                                grep -v "8.4" |
                                sort -u -t. -k1n -k2n)"
            echo "found PostgreSQL versions:" >&2
            echo >&2
            echo "$postgres_versions"
            return
        fi
    fi
    echo "$postgres_versions" |
    tr ' ' '\n' |
    grep -v '^[[:space:]]*$' |
    if is_CI; then
        echo "CI detected - using randomized sample of PostgreSQL versions to test against:" >&2
        {
        shuf | head -n 1
        echo 9.1  # most problematic / incompatible versions should always be tested
        echo 9.5
        echo latest
        } | sort -unr -t. -k1,2
    else
        echo "using default list of PostgreSQL versions to test against:" >&2
        cat
    fi
    echo >&2
}

if [ -n "${POSTGRESQL_VERSIONS:-${POSTGRES_VERSIONS:-}}" ]; then
    versions=""
    POSTGRES_VERSIONS="${POSTGRESQL_VERSIONS:-$POSTGRES_VERSIONS}"
    POSTGRES_VERSIONS="${POSTGRES_VERSIONS//,/ }"
    for version in $POSTGRES_VERSIONS; do
        if [[ "$version" =~ x ]]; then
            versions+=" $(grep "${version//x/.*}" <<< "$postgres_versions" |
                          sort -u -t. -k1n -k2 |
                          tac ||
                          die "version '$version' not found")"
        else
            versions+=" $version"
        fi
    done
    postgres_versions="$(tr ' ' '\n' <<< "$versions" | grep -v '^[[:space:]]*$')"
    echo "using given PostgreSQL versions:" >&2
else
    postgres_versions="$(get_postgres_versions | tac)"
fi

echo "$postgres_versions"
echo

for version in $postgres_versions; do
    hr
    echo "Executing scripts against PostgreSQL version '$version'": >&2
    echo >&2
    {
    echo 'SELECT VERSION();'
    for sql_file in "${scripts[@]}"; do
        if skip_min_version "PostgreSQL" "$version" "$sql_file"; then
            continue
        fi
        if skip_max_version "PostgreSQL" "$version" "$sql_file"; then
            continue
        fi
        echo '\! printf "================================================================================\n"'
        # no effect
        #echo
        echo '\set ON_ERROR_STOP true'
        # ugly
        #echo "select '$sql_file' as script;"
        echo "\\! printf '\\nscript %s:\\n\\n' '$sql_file'"
        # instead of dealing with pathing issues, prefixing /pwd or depending on the scripts being in the sql/ directory
        #echo "\\i $sql_file"
        cat "$sql_file"
        echo "\\! printf '\\n\\n'"
    done
    } |
    command time "$srcdir/postgres.sh" "$version" --restart
    echo >&2
    timestamp "Succeeded testing ${#scripts[@]} scripts for PostgreSQL $version"
    echo >&2
    echo >&2
done
echo >&2
echo >&2
timestamp "All PostgreSQL tests passed for all scripts on all versions:  $(tac <<< "$postgres_versions" | tr '\n' ' ')"
