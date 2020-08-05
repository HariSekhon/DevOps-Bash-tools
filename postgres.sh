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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Boots a quick postgres Docker container and drops you in to the 'psql' shell

Docker automatic mount points inside the container:

sql   => /sql
repo  => /code
\$PWD => /pwd

You can quickly test scripts via include, eg.

\i /sql/postgres_running_queries.sql
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

container_name=postgres

password="${PGPASSWORD:-${POSTGRESQL_PASSWORD:-${POSTGRES_PASSWORD:-test}}}"

if ! docker ps -qf name=postgres | grep -q .; then
    timestamp 'booting postgres container:'
    docker run -d -ti \
               --name "$container_name" \
               -e POSTGRES_PASSWORD="$password" \
               -v "$srcdir:/bash" \
               -v "$srcdir/sql:/sql" \
               -v "$HOME/github:/github" \
               -v "$PWD:/pwd" \
               -v "$srcdir/setup/postgresql.conf:/etc/postgresql/postgresql.conf" \
               postgres \
                    -c 'config_file=/etc/postgresql/postgresql.conf'

    timestamp 'waiting for postgres to be ready to accept connections before connecting psql...'
    while true; do
        if docker logs --tail 10 "$container_name" | grep 'ready to accept connections'; then
            break
        fi
        sleep 0.1
    done
    echo
fi

cat <<EOF
SQL  scripts are mounted at /sql
Bash scripts are mounted at /bash
\$HOME/github  is mounted at /github

To source a SQL script, do:

\i /sql/<file>.sql

EOF

docker exec -ti postgres psql -U postgres

# not cleaning up the postgres container by default in case we want to maintain state for testing
#docker rm -f postgres
