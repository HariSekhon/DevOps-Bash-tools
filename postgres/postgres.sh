#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-05 13:42:41 +0100 (Wed, 05 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://hub.docker.com/_/postgres

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/dbshell.sh"

# defined in lib/dbshell.sh
# shellcheck disable=SC2154
shell_description="$sql_mount_description

Source a sql script:

\\i postgres_info.sql


Get shell access:

\\!


List available SQL scripts:

\\! ls -l postgres*.sql
"

# shellcheck disable=SC2034,SC2154
usage_description="
Boots a quick PostgreSQL docker container and drops you in to the 'psql' shell

Multiple invocations of this script will connect to the same Postgres container if already running
and the last invocation of this script to exit from the psql shell will delete that container

PostgresSQL version can be specified using the first argument, or the \$POSTGRES_VERSION environment variable,
otherwise 'latest' is used

Versions to use can be found from the following URL:

https://hub.docker.com/_/postgres?tab=tags

or programmatically on the command line (see DevOps Python tools repo):

dockerhub_show_tags.py postgres


Automatically creates shared bind mount points from host to container for convenience:
$shell_description


Tested on PostgreSQL 8.4, 9.x, 10.x, 11.x, 12.x, 13.0
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>] [options]

-n  --name  NAME    Docker container name to use (default: postgres)
-p  --port  PORT    Expose PostgreSQL port 5432 on given port number
-d  --no-delete     Don't delete the container upon the last psql session closing (\$DOCKER_NO_DELETE)
-r  --restart       Force a restart of a clean PostgreSQL instance (\$POSTGRES_RESTART)
-s  --sample        Load sample Chinook database (\$LOAD_SAMPLE)"

help_usage "$@"

docker_image=postgres
port=""
docker_opts=""

password="${PGPASSWORD:-${POSTGRESQL_PASSWORD:-${POSTGRES_PASSWORD:-${PASSWORD:-test}}}}"

while [ $# -gt 0 ]; do
    # DOCKER_NO_DELETE used by functions from lib
    # shellcheck disable=SC2034
    case "$1" in
      -n| --name)   container_name="$2"
                    shift
                    ;;
      -p| --port)   port="$2"
                    [[ "$port" =~ ^[[:digit:]]*$ ]] || die "invalid --port '$port' given"
                    shift
                    ;;
     -s|--sample)   LOAD_SAMPLE_DB=1
                    ;;
    -r|--restart)   POSTGRES_RESTART=1
                    ;;
  -d|--no-delete)   DOCKER_NO_DELETE=1
                    ;;
               *)   version="$1"
                    ;;
    esac
    shift
done

container_name="${container_name:-${POSTGRES_CONTAINER_NAME:-postgres}}"
version="${version:-${POSTGRESQL_VERSION:-${POSTGRES_VERSION:-latest}}}"

if [ -n "$port" ]; then
    docker_opts="-p $port:5432"
fi

db="$srcdir/chinook.psql"

if [ -n "${LOAD_SAMPLE_DB:-}" ] &&
   ! [ -f "$db.utf8" ]; then
    timestamp "downloading sample 'chinook' database"
    wget -qcO "$db" 'https://github.com/lerocha/chinook-database/blob/master/ChinookDatabase/DataSources/Chinook_PostgreSql.sql?raw=true'
    iconv -f ISO-8859-1 -t UTF-8 "$db" > "$db.utf8"
fi

# kill existing if we have specified a different version than is running
docker_image_version="$(docker_container_image "$container_name")"
if [ -n "$docker_image_version" ] &&
   [ "$docker_image_version" != "$docker_image:$version" ]; then
    POSTGRES_RESTART=1
fi

# remove existing non-running container so we can boot a new one
if docker_container_not_running "$container_name"; then
    POSTGRES_RESTART=1
fi

if [ -n "${POSTGRES_RESTART:-}" ]; then
    # ensures version is correct before we kill any existing test env to switch versions to minimize downtime
    timestamp "docker pull $docker_image:$version"
    docker_pull "$docker_image:$version"

    timestamp "killing existing container:"
    docker rm -f -- "$container_name" 2>/dev/null || :
fi

if ! docker_container_exists "$container_name"; then
    timestamp "booting PostgreSQL container from image '$docker_image:$version':"
    # defined in lib/dbshell.sh
    # shellcheck disable=SC2154,SC2086,SC2046
    docker run -d \
        --name "$container_name" \
        $docker_opts \
        -e POSTGRES_PASSWORD="$password" \
        -v "$srcdir/../setup/postgresql.conf:/etc/postgresql/postgresql.conf" \
        $docker_sql_mount_switches \
        "$docker_image":"$version" \
        $(if [ "${version:0:1}" = 8 ] || [ "${version:0:3}" = '9.0' ]; then echo postgres; fi) \
        -c 'config_file=/etc/postgresql/postgresql.conf'
        # can't mount postgresql.conf here because it prevents /var/lib/postgresql/data from being initialized
        #-v "$srcdir/../setup/postgresql.conf:/var/lib/postgresql/data/postgresql.conf"
fi

wait_for_postgres_ready "$container_name"
echo

timestamp "linking shell profile for .psqlrc"
docker exec "$container_name" bash -c "cd /bash && setup/shell_link.sh &>/dev/null" || :

# yes expand now
# shellcheck disable=SC2064
trap "echo ERROR; echo; echo; [ -z '${DEBUG:-}' ] || docker logs '$container_name'" EXIT

if [ -n "${LOAD_SAMPLE_DB:-}" ]; then
    dbname="${db##*/}"
    dbname="${dbname%%.*}"
    timestamp "loading $dbname database"
    # psql -c doesn't allow mixing SQL and psql meta-commands, must pipe in
    # create database if not exists equiv in postgres                                                         # \gexec executes each column returned as a SQL statement
    echo "SELECT 'CREATE DATABASE $dbname' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$dbname')\\gexec" |
    docker exec -i -e PGOPTIONS="-c client_min_messages=WARNING" "$container_name" psql -U postgres
    timestamp "loading data (this may take a minute)"
    docker exec -e PGOPTIONS="-c client_min_messages=WARNING" "$container_name" psql -U postgres -q -d "$dbname" -f "/bash/${db##*/}.utf8"
    timestamp "done"
    echo >&2
fi

if has_terminal && [ -z "${DOCKER_NO_TERMINAL:-}" ]; then
    cat <<EOF
$shell_description

EOF
fi

# cd to /sql to make sourcing easier without /sql/ path prefix
docker_exec_opts="-w /sql -i"

# allow non-interactive piped automation to avoid tty errors eg.
# for sql in postgres*.sql; do echo "source $sql"; done | postgres.sh
# normally you would just 'postgres.sh postgres*.sql' but this is used by postgres_test_scripts.sh
if has_terminal && [ -z "${DOCKER_NO_TERMINAL:-}" ]; then
    docker_exec_opts+=" -t"
fi

# want opt splitting
# shellcheck disable=SC2086
docker exec $docker_exec_opts "$container_name" /bash/psql_colorized.sh -U postgres

untrap

docker_rm_when_last_connection "$0" "$container_name"
