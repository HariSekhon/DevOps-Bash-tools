#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC2034
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sql_scripts="$srcdir/sql"
if [ -d "$srcdir/../sql" ]; then
    sql_scripts="$srcdir/../sql"
fi

sql_mount_description="
SQL  scripts     => /sql  <- session \$PWD for convenient sql sourcing
Bash scripts     => /bash
\$PWD             => /pwd
\$HOME/github     => /github
"

docker_sql_mount_switches=" \
    -v '$srcdir:/bash' \
    -v '$sql_scripts:/sql' \
    -v '$HOME/github:/github' \
    -v '$PWD:/pwd' \
"

wait_for_mysql_ready(){
    local container_name="$1"
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
            echo "container '$container_name' failed to become ready for connections within reasonable time, check logs (format may have changed):"
            echo
            docker logs "$container_name"
            exit 1
        fi
    done
}

docker_rm_when_last_connection(){
    local scriptname="$1"
    local container_name="$2"
    if [ "$(lsof -lnt "$scriptname" | grep -c .)" -lt 2 ]; then
    #if [ "$(pgrep -lf "bash.*${0##*/}" | grep -c .)" -lt 2 ]; then
    #if [ "$(ps -ef | grep -c "[b]ash.*${0##*/}")" -lt 2 ]; then
        echo "last session closing, deleting container:"
        docker rm -f "$container_name"
    fi
}
