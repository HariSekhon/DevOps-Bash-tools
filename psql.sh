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

# Script to more easily connect to PostgreSQL without having to find an impalad and repeatedly specify options like username and password
#
# Leverages standard PostgresSQL options as well as others likely to be found in the environment
#
# https://www.postgresql.org/docs/9.0/libpq-envars.html
#
# Tested on AWS RDS PostgreSQL 9.5.15

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

opts="${POSTGRES_OPTS:-}"


POSTGRES_HOST="${PGHOST:-${POSTGRES_HOST:-${HOST:-}}}"
if [ -n "${POSTGRES_HOST:-}" ]; then
    # more intuitive to see in the process list what is going on
    #export PGHOST="$POSTGRES_HOST"
    opts="$opts -h $POSTGRES_HOST"
fi

POSTGRES_PORT="${PGPORT:-${POSTGRES_PORT:-${PORT:-}}}"
if [ -n "${POSTGRES_PORT:-}" ]; then
    # more intuitive to see in the process list what is going on
    #export PGPORT="$POSTGRES_PORT"
    opts="$opts -p $POSTGRES_PORT"
fi

POSTGRES_USER="${PGUSER:-${POSTGRES_USER:-${USER:-}}}"
if [ -n "${POSTGRES_USER:-}" ]; then
    # more intuitive to see in the process list what is going on
    #export PGUSER="$POSTGRES_USER"
    opts="$opts -U $POSTGRES_USER"
fi

POSTGRES_PASSWORD="${PGPASSWORD:-${POSTGRES_PASSWORD:-${PASSWORD:-}}}"
if [ -n "${POSTGRES_PASSWORD:-}" ]; then
    # can't do this and wouldn't want to as it'd expose it in the password list
    #opts="$opts -U $POSTGRES_PASSWORD"
    export PGPASSWORD="$POSTGRES_PASSWORD"
fi

POSTGRES_DATABASE="${PGDATABASE:-${POSTGRES_DATABASE:-${DATABASE:-}}}"
if [ -n "${POSTGRES_DATABASE:-}" ]; then
    # more intuitive to see in the process list what is going on
    #export PGDATABASE="$POSTGRES_DATABASE"
    opts="$opts -d $POSTGRES_DATABASE"
fi

# split opts
# shellcheck disable=SC2086
psql $opts "$@"
