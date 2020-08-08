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

# shellcheck disable=SC1090
. "$srcdir/lib/dbshell.sh"

# defined in lib/dbshell.sh
# shellcheck disable=SC2154
shell_description="$sql_mount_description

Source a sql script:

\i /sql/postgres_info.sql


Get shell access:

\!


List available SQL scripts:

\! ls -l
"

# shellcheck disable=SC2034,SC2154
usage_description="
Boots a quick PostgreSQL docker container and drops you in to the 'psql' shell

Multiple invocations of this script will connect to the same Postgres container if already running
and the last invocation of this script to exit from the psql shell will delete that container

An argument can be given to specify the docker tag version of PostgreSQL,
or infers from the \$POSTGRES_VERSION environment variable if set, otherwise 'latest' is used

Automatically creates shared bind mount points from host to container for convenience:
$shell_description
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

docker_image=postgres
container_name=postgres
version="${1:-${POSTGRESQL_VERSION:-${POSTGRES_VERSION:-latest}}}"

password="${PGPASSWORD:-${POSTGRESQL_PASSWORD:-${POSTGRES_PASSWORD:-test}}}"

# ensures version is correct before we kill any existing test env to switch versions
docker_pull "$docker_image:$version"

docker_ps_image_version="$(docker ps --filter "name=$container_name" --format '{{.Image}}')"
if [ -n "$docker_ps_image_version" ] &&
   [ "$docker_ps_image_version" != "$docker_image:$version" ]; then
    POSTGRES_RESTART=1
fi

# remove existing non-running container so we can boot a new one
if docker_ps_not_running "name=$container_name"; then
    POSTGRES_RESTART=1
fi

if [ -n "${POSTGRES_RESTART:-}" ]; then
    timestamp "killing existing container:"
    docker rm -f "$container_name" 2>/dev/null || :
fi

if ! docker ps -qf name="$container_name" | grep -q .; then
    timestamp "booting PostgreSQL container from image '$docker_image:$version':"
    # defined in lib/dbshell.sh
    # shellcheck disable=SC2154
    eval docker run -d \
        --name "$container_name" \
        -p 5432:5432 \
        -e POSTGRES_PASSWORD="$password" \
        "$docker_sql_mount_switches" \
        -v "$srcdir/setup/postgresql.conf:/etc/postgresql/postgresql.conf" \
        "$docker_image":"$version" \
        -c 'config_file=/etc/postgresql/postgresql.conf'

    SECONDS=0
    timestamp 'waiting for postgres to be ready to accept connections before connecting psql...'
    while true; do
        if [ "$(docker logs "$container_name" 2>&1 | grep -c 'ready to accept connections')" -ge 1 ]; then
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
$shell_description

EOF

trap "echo ERROR; echo; echo; docker logs '$container_name'" EXIT

docker exec -ti -w /sql "$container_name" psql -U postgres

untrap

docker_rm_when_last_connection "$0" "$container_name"
