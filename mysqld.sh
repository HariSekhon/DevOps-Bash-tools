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

Automatically createst shared bind mount points inside the container for convenience:

sql   => /sql
repo  => /code
\$PWD => /pwd

You can quickly test scripts via include, eg.

\i /sql/mysql_running_queries.sql
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

container_name=mysql
version="${MYSQL_VERSION:-latest}"

password="${MYSQL_ROOT_PASSWORD:-${MYSQL_PWD:-${MYSQL_PASSWORD:-test}}}"

if ! docker ps -qf name=mysql | grep -q .; then
    timestamp 'booting MySQL container:'
    docker run -d -ti \
               --name "$container_name" \
               -p 3306:3306 \
               -e MYSQL_ROOT_PASSWORD="$password" \
               -v "$srcdir:/bash" \
               -v "$srcdir/sql:/sql" \
               -v "$HOME/github:/github" \
               -v "$PWD:/pwd" \
               mysql:"$version"
               #-v "$srcdir/setup/mysql/conf.d/my.cnf:/etc/mysql/conf.d/" \

    timestamp 'waiting for mysql to be ready to accept connections before connecting to mysql shell...'
    while true; do
        if docker logs --tail 10 "$container_name" | grep 'mysqld.*ready to accept connections'; then
            break
        fi
        sleep 0.5
    done
    echo
fi

cat <<EOF
SQL  scripts are mounted at /sql
Bash scripts are mounted at /bash
\$PWD          is mounted at /pwd
\$HOME/github  is mounted at /github

To source a SQL script, do:

source /sql/<file>.sql

\! bash     to get to shell command line

EOF

docker exec -ti mysql mysql -u root -p"$password"

# not cleaning up the mysql container by default in case we want to maintain state for testing
#docker rm -f mysql
