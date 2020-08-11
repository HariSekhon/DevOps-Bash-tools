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
host \$PWD        => /pwd
\$HOME/github     => /github
"

docker_sql_mount_switches=" \
    -v '$srcdir:/bash' \
    -v '$sql_scripts:/sql' \
    -v '$HOME/github:/github' \
    -v '$PWD:/pwd' \
"

# MySQL 5.5 container
#
# MySQL init process done. Ready for start up.
# ...
# 200808 19:30:58 [Note] mysqld: ready for connections.
wait_for_mysql_ready(){
    local container_name="$1"
    local tries=0
    local num_lines=50
    while true; do
        ((tries+=1))
        if [ $((tries % 5)) = 0 ]; then
            timestamp 'waiting for mysqld to be ready to accept connections before connecting mysql shell...'
        fi
        if docker logs --tail "$num_lines" "$container_name" 2>&1 |
            grep -i -A "$num_lines" \
                 -e 'Entrypoint.*Ready' \
                 -e 'MySQL init process done' |
            grep -q \
                 -e 'mysqld.*ready for connections' \
                 -e 'mysqld.*ready to accept connections'; then
            break
        fi
        sleep 1
        if [ $tries -gt 60 ]; then
            timestamp "container '$container_name' failed to become ready for connections within reasonable time, check logs (format may have changed):"
            echo >&2
            docker logs "$container_name"
            exit 1
        fi
    done
}

docker_rm_when_last_connection(){
    local scriptname="$1"
    local container_name="$2"
    [ -z "${DOCKER_NO_DELETE:-}" ] || return
    if [ "$(lsof -lnt "$scriptname" | grep -c .)" -lt 2 ]; then
    #if [ "$(pgrep -lf "bash.*${0##*/}" | grep -c .)" -lt 2 ]; then
    #if [ "$(ps -ef | grep -c "[b]ash.*${0##*/}")" -lt 2 ]; then
        timestamp "last session closing, deleting container:"
        docker rm -f "$container_name"
    fi
}

# detect version headers and only run if the version corresponds
skip_min_version(){
    local sql_file="$1"
    local version="$2"
    local min_version
    local inclusive=""
    # some versions of sed don't support +, so stick to *
    min_version="$(grep -Eio -- '--[[:space:]]Requires[[:space:]]+MySQL[[:space:]](>=?)?[[:space:]]*[[:digit:]]+(\.[[:digit:]]+)?' "$sql_file" | sed 's/.*Requires *MySQL *//' || :)"
    if [ -n "$min_version" ] &&
       [ "$version" != latest ]; then
        if [[ "$min_version" =~ \= ]] ||
           ! [[ "$min_version" =~ \> ]]; then
            inclusive="="
        fi
        min_version="${min_version#>}"
        min_version="${min_version#=}"
        skip_msg="skipping script '$sql_file' due to min requirement version >$inclusive $min_version"
        if [ -n "$inclusive" ]; then
            if bc_bool "$version < $min_version"; then
                timestamp "$skip_msg"
                return 0
            fi
        else
            if bc_bool "$version <= $min_version"; then
                timestamp "$skip_msg"
                return 0
            fi
        fi
    fi
    return 1
}

# detect version headers and only run if the version corresponds
skip_max_version(){
    local sql_file="$1"
    local version="$2"
    local max_version
    local inclusive=""
    max_version="$(grep -Eio -- '--[[:space:]]Requires[[:space:]]+MySQL[[:space:]]<=?[[:space:]][[:digit:]]+(\.[[:digit:]]+)?' "$sql_file" | sed 's/.*Requires *MySQL *//' || :)"
    if [ -n "$max_version" ]; then
        if [[ "$max_version" =~ = ]]; then
            inclusive="="
        fi
        skip_msg="skipping script '$sql_file' due to max requirement version <$inclusive $max_version"
        if [ "$version" != latest ]; then
            timestamp "$skip_msg"
            return 0
        fi
        max_version="${max_version#<}"
        max_version="${max_version#=}"
        if [ "$inclusive" = 1 ]; then
            if bc_bool "$version > $max_version"; then
                timestamp "$skip_msg"
                return 0
            fi
        else
            if bc_bool "$version >= $max_version"; then
                timestamp "$skip_msg"
                return 0
            fi
        fi
    fi
    return 1
}
