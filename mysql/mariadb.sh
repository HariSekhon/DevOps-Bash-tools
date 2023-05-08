#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-05 19:49:48 +0100 (Wed, 05 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://hub.docker.com/_/mariadb

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

source mysql_info.sql


Get shell access:

\\! bash


List available SQL scripts:

\\! ls -l mysql*.sql
"

# shellcheck disable=SC2034,SC2154
usage_description="
Boots a quick MariaDB docker container and drops you in to the 'mysql' shell

Multiple invocations of this script will connect to the same MariaDB container if already running
and the last invocation of this script to exit from the mysql shell will delete that container

MariaDB version can be specified using the first argument, or the \$MARIADB_VERSION environment variable,
otherwise 'latest' is used

Versions to use can be found from the following URL:

https://hub.docker.com/_/mariadb?tab=tags

or programmatically on the command line (see DevOps Python tools repo):

dockerhub_show_tags.py mariadb


Options to the 'mysql' shell command can be given using the \$MYSQL_OPTS environment variable

Automatically creates shared bind mount points from host to container for convenience:
$shell_description


Tested on MariaDB 5.5, 10.0 - 10.5
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>] [options]

-n  --name  NAME    Docker container name to use (default: mariadb)
-p  --port  PORT    Expose MariaDB port 3306 on given port number
-d  --no-delete     Don't delete the container upon the last mysql session closing (\$DOCKER_NO_DELETE)
-r  --restart       Force a restart of a clean MariaDB instance (\$MARIADB_RESTART)
-s  --sample        Load sample Chinook database (\$LOAD_SAMPLE)"

help_usage "$@"

docker_image=mariadb
port=""
docker_opts=""

password="${MYSQL_ROOT_PASSWORD:-${MYSQL_PWD:-${MYSQL_PASSWORD:-${PASSWORD:-test}}}}"

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
    -r|--restart)   MARIADB_RESTART=1
                    ;;
  -d|--no-delete)   DOCKER_NO_DELETE=1
                    ;;
               *)   version="$1"
                    ;;
    esac
    shift
done

container_name="${container_name:-${MARIADB_CONTAINER_NAME:-mariadb}}"
version="${version:-${MARIADB_VERSION:-latest}}"

if [ -n "$port" ]; then
    docker_opts="-p $port:5432"
fi

db="$srcdir/chinook.mysql"

if [ -n "${LOAD_SAMPLE_DB:-}" ] &&
   ! [ -f "$db" ]; then
    timestamp "downloading sample 'chinook' database"
    wget -qcO "$db" 'https://github.com/lerocha/chinook-database/blob/master/ChinookDatabase/DataSources/Chinook_MySql.sql?raw=true'
    #iconv -f ISO-8859-1 -t UTF-8 "$db" > "$db.utf8"
fi

# kill existing if we have specified a different version than is running
docker_image_version="$(docker_container_image "$container_name")"
if [ -n "$docker_image_version" ] &&
   [ "$docker_image_version" != "$docker_image:$version" ]; then
    MARIADB_RESTART=1
fi

# remove existing non-running container so we can boot a new one
if docker_container_not_running "$container_name"; then
    MARIADB_RESTART=1
fi

if [ -n "${MARIADB_RESTART:-}" ]; then
    # ensures version is correct before we kill any existing test env to switch versions to minimize downtime
    timestamp "docker pull $docker_image:$version"
    docker_pull "$docker_image:$version"

    timestamp "killing existing MariaDB container:"
    docker rm -f -- "$container_name" 2>/dev/null || :
fi

if ! docker_container_exists "$container_name"; then
    timestamp "booting MariaDB container from image '$docker_image:$version':"
    # defined in lib/dbshell.sh
    # shellcheck disable=SC2154,SC2086
    docker run -d \
        --name "$container_name" \
        $docker_opts \
        -e MYSQL_ROOT_PASSWORD="$password" \
        $docker_sql_mount_switches \
        "$docker_image":"$version"
        #-v "$srcdir/../setup/mysql/conf.d/my.cnf:/etc/mysql/conf.d/" \
fi

wait_for_mysql_ready "$container_name"
echo

timestamp "linking shell profile for .my.cnf"
docker exec "$container_name" bash -c "cd /bash && setup/shell_link.sh &>/dev/null" || :

# yes expand now
# shellcheck disable=SC2064
trap "echo ERROR; echo; echo; [ -z '${DEBUG:-}' ] || docker logs '$container_name'" EXIT

if [ -n "${LOAD_SAMPLE_DB:-}" ]; then
    dbname="${db##*/}"
    dbname="${dbname%%.*}"
    timestamp "loading $dbname database"
    #docker exec -i "$container_name" mysql -u root -p"$password" ${MYSQL_OPTS:-} -e "CREATE DATABASE IF NOT EXISTS $dbname"
    timestamp "loading data (this may take a minute)"
    # shellcheck disable=SC2086
    docker exec -i -e MYSQL_PWD="$password" "$container_name" mysql -u root ${MYSQL_OPTS:-} < "${db}"
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
# for sql in mysql*.sql; do echo "source $sql"; done | mariadb.sh
# normally you would just 'mariadb.sh mysql*.sql' but this is used by mariadb_test_scripts.sh
if has_terminal && [ -z "${DOCKER_NO_TERMINAL:-}" ]; then
    docker_exec_opts+=" -t"
fi

# want opt splitting
# shellcheck disable=SC2154,SC2086
docker exec -e MYSQL_PWD="$password" $docker_exec_opts "$container_name" mysql -u root ${MYSQL_OPTS:-}

untrap

docker_rm_when_last_connection "$0" "$container_name"
