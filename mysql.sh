#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-12 16:15:38 +0000 (Thu, 12 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to more easily connect to MySQL without having to repeatedly specify options like host, username and password
#
# Leverages standard MySQL options as well as others likely to be found in the environment
#
# https://dev.mysql.com/doc/refman/8.0/en/environment-variables.html
#
# Tested on 8.0.15

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

opts="${MYSQL_OPTS:-}"


MYSQL_HOST="${MYSQL_HOST:-${HOST:-}}"
if [ -n "${MYSQL_HOST:-}" ]; then
    opts="$opts -h $MYSQL_HOST"
fi

MYSQL_PORT="${MYSQL_TCP_PORT:-${MYSQL_PORT:-${PORT:-}}}"
if [ -n "${MYSQL_PORT:-}" ]; then
    opts="$opts -P $MYSQL_PORT"
fi

MYSQL_USER="${MYSQL_USER:-${DBI_USER:-${USER:-}}}"
if [ -n "${MYSQL_USER:-}" ]; then
    opts="$opts -u $MYSQL_USER"
fi

MYSQL_PASSWORD="${MYSQL_PWD:-${MYSQL_PASSWORD:-${PASSWORD:-}}}"
if [ -n "${MYSQL_PASSWORD:-}" ]; then
    echo "WARNING: not auto-adding -p<password> for safety" >&2
    #opts="$opts -p$MYSQL_PASSWORD"
    :
fi

MYSQL_DATABASE="${MYSQL_DATABASE:-${DATABASE:-}}"
if [ -n "${MYSQL_DATABASE:-}" ]; then
    opts="$opts -d $MYSQL_DATABASE"
fi

# split opts
# shellcheck disable=SC2086
mysql $opts "$@"
