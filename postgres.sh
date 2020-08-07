#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-05 13:42:41 +0100 (Wed, 05 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# https://hub.docker.com/_/postgres

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Boots a quick PostgreSQL docker container and drops you in to the 'psql' shell

Automatically creates shared bind mount points inside the container for convenience:

sql   => /sql
repo  => /code
\$PWD => /pwd

You can quickly test scripts via include, eg.

\i /sql/postgres_running_queries.sql

Multiple invocations of this script will connect to the same Postgres container if already running
and the last invocation of this script to exit from the psql shell will delete that container
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

container_name=postgres
version="${POSTGRESQL_VERSION:-${POSTGRES_VERSION:-latest}}"

password="${PGPASSWORD:-${POSTGRESQL_PASSWORD:-${POSTGRES_PASSWORD:-test}}}"

sql_scripts="$srcdir/sql"
if [ -d "$srcdir/../sql" ]; then
    sql_scripts="$srcdir/../sql"
fi

if ! docker ps -qf name="$container_name" | grep -q .; then
    timestamp 'booting postgres container:'
    docker run -d -ti \
               --name "$container_name" \
               -p 5432:5432 \
               -e POSTGRES_PASSWORD="$password" \
               -v "$srcdir:/bash" \
               -v "$sql_scripts:/sql" \
               -v "$HOME/github:/github" \
               -v "$PWD:/pwd" \
               -v "$srcdir/setup/postgresql.conf:/etc/postgresql/postgresql.conf" \
               postgres:"$version" \
                    -c 'config_file=/etc/postgresql/postgresql.conf'

    SECONDS=0
    timestamp 'waiting for postgres to be ready to accept connections before connecting psql...'
    while true; do
        if [ "$(docker logs "$container_name" | grep -c 'ready to accept connections')" -gt 1 ]; then
            break
        fi
        sleep 0.1
        if [ $SECONDS -gt 20 ]; then
            echo "PostgreSQL failed to become ready for connections within 20 secs, check logs (format may have changed):"
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

\i /sql/<file>.sql

\! to get to shell command line

EOF

docker exec -ti -w /sql postgres psql -U postgres

if [ "$(lsof -lnt "$0" | grep -c .)" -lt 2 ]; then
    echo "last session closing, deleting container:"
    docker rm -f "$container_name"
fi
