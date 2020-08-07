#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-05 19:49:48 +0100 (Wed, 05 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://hub.docker.com/_/mysql

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Boots a quick MySQL docker container and drops you in to the 'mysql' shell

Automatically creates shared bind mount points inside the container for convenience:

sql   => /sql
repo  => /code
\$PWD => /pwd

You can quickly test scripts via include, eg.

\i /sql/mysql_running_queries.sql

Multiple invocations of this script will connect to the same MySQL container if already running
and the last invocation of this script to exit from the mysql shell will delete that container
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

container_name=mysql
version="${MYSQL_VERSION:-latest}"

password="${MYSQL_ROOT_PASSWORD:-${MYSQL_PWD:-${MYSQL_PASSWORD:-test}}}"

sql_scripts="$srcdir/sql"
if [ -d "$srcdir/../sql" ]; then
    sql_scripts="$srcdir/../sql"
fi

if ! docker ps -qf name="$container_name" | grep -q .; then
    timestamp 'booting MySQL container:'
    docker run -d -ti \
               --name "$container_name" \
               -p 3306:3306 \
               -e MYSQL_ROOT_PASSWORD="$password" \
               -v "$srcdir:/bash" \
               -v "$sql_scripts:/sql" \
               -v "$HOME/github:/github" \
               -v "$PWD:/pwd" \
               mysql:"$version"
               #-v "$srcdir/setup/mysql/conf.d/my.cnf:/etc/mysql/conf.d/" \

    tries=0
    while true; do
        ((tries+=1))
        if [ $((tries % 5)) = 0 ]; then
            timestamp 'waiting for mysqld to be ready to accept connections before connecting mysql shell...'
        fi
        if docker logs --tail 10 "$container_name" |
            grep -e 'mysqld.*ready for connections' \
                 -e 'mysqld.*ready to accept connections'; then
            break
        fi
        sleep 1
        if [ $tries -gt 60 ]; then
            echo "MySQL container failed to become ready for connections within reasonable time, check logs (format may have changed):"
            echo
            docker logs "$container_name"
            exit 1
        fi
    done
    echo
fi

cat <<EOF
SQL  scripts are mounted at => /sql
Bash scripts are mounted at => /bash
\$PWD          is mounted at => /pwd
\$HOME/github  is mounted at => /github

To source a SQL script, do:

source /sql/<file>.sql

\.     /sql/<file>.sql


To get to shell command line:

\! bash

EOF

docker exec -ti -w /sql "$container_name" mysql -u root -p"$password"

if [ "$(lsof -lnt "$0" | grep -c .)" -lt 2 ]; then
#if [ "$(pgrep -lf "bash.*${0##*/}" | grep -c .)" -lt 2 ]; then
#if [ "$(ps -ef | grep -c "[b]ash.*${0##*/}")" -lt 2 ]; then
    echo "last session closing, deleting container:"
    docker rm -f "$container_name"
fi
