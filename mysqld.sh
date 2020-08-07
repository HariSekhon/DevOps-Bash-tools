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
Boots a quick MySQL docker container and drops you in to the 'mysql' shell

Multiple invocations of this script will connect to the same MySQL container if already running
and the last invocation of this script to exit from the mysql shell will delete that container

Automatically creates shared bind mount points from host to container for convenience:
$shell_description
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

docker_image=mysql
container_name=mysql
version="${MYSQL_VERSION:-latest}"

password="${MYSQL_ROOT_PASSWORD:-${MYSQL_PWD:-${MYSQL_PASSWORD:-test}}}"

if ! docker ps -qf name="$container_name" | grep -q .; then
    timestamp "booting MySQL container from image '$docker_image:$version':"
    # defined in lib/dbshell.sh
    # shellcheck disable=SC2154
    eval docker run -d \
        --name "$container_name" \
        -p 3306:3306 \
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

docker exec -ti -w /sql "$container_name" mysql -u root -p"$password"

docker_rm_when_last_connection "$0" "$container_name"
