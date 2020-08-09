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

# https://hub.docker.com/_/mariadb

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

source mysql_info.sql


Get shell access:

\! bash


List available SQL scripts:

\! ls -l
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


Automatically creates shared bind mount points from host to container for convenience:
$shell_description
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

docker_image=mariadb
container_name=mariadb
version="${1:-${MARIADB_VERSION:-latest}}"

password="${MYSQL_ROOT_PASSWORD:-${MYSQL_PWD:-${MYSQL_PASSWORD:-test}}}"

# ensures version is correct before we kill any existing test env to switch versions
docker_pull "$docker_image:$version"

# kill existing if we have specified a different version than is running
docker_ps_image_version="$(docker ps --filter "name=$container_name" --format '{{.Image}}')"
if [ -n "$docker_ps_image_version" ] &&
   [ "$docker_ps_image_version" != "$docker_image:$version" ]; then
    MARIADB_RESTART=1
fi

# remove existing non-running container so we can boot a new one
if docker_ps_not_running "name=$container_name"; then
    MARIADB_RESTART=1
fi

if [ -n "${MARIADB_RESTART:-}" ]; then
    timestamp "killing existing MariaDB container:"
    docker rm -f "$container_name" 2>/dev/null || :
fi

if ! docker ps -qf name="$container_name" | grep -q .; then
    timestamp "booting MariaDB container from image '$docker_image:$version':"
    # defined in lib/dbshell.sh
    # shellcheck disable=SC2154
    eval docker run -d \
        --name "$container_name" \
        -p 3307:3306 \
        -e MYSQL_ROOT_PASSWORD="$password" \
        "$docker_sql_mount_switches" \
        "$docker_image":"$version"
        #-v "$srcdir/setup/mysql/conf.d/my.cnf:/etc/mysql/conf.d/" \

    wait_for_mysql_ready "$container_name"
    echo
fi

cat <<EOF
$shell_description

EOF

trap "echo ERROR; echo; echo; docker logs '$container_name'" EXIT

docker exec -ti -w /sql "$container_name" mysql -u root -p"$password"

untrap

docker_rm_when_last_connection "$0" "$container_name"
