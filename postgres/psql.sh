#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-12 16:15:38 +0000 (Thu, 12 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Script to more easily connect to PostgreSQL without having to repeatedly specify options like host, username and password

Leverages standard PostgresSQL options as well as others likely to be found in the environment

https://www.postgresql.org/docs/9.0/libpq-envars.html

See also - GNU sql

Tested on PostgreSQL 8.4, 9.x, 10.x, 11.x, 12.x, 13.0
          AWS RDS PostgreSQL 9.5.15
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<psql_options>]"

# would catch -h but this is a legit option we should let through
#help_usage "$@"

#min_args 1 "$@"

for arg; do
    case "$arg" in
        --help) usage
                ;;
    esac
done

opts="${POSTGRES_OPTS:-}"

POSTGRES_HOST="${PGHOST:-${POSTGRESQL_HOST:-${POSTGRES_HOST:-${HOST:-}}}}"
if [ -n "${POSTGRES_HOST:-}" ]; then
    # more intuitive to see in the process list what is going on
    #export PGHOST="$POSTGRES_HOST"
    opts="$opts -h $POSTGRES_HOST"
fi

POSTGRES_PORT="${PGPORT:-${POSTGRESQL_PORT:-${POSTGRES_PORT:-${PORT:-}}}}"
if [ -n "${POSTGRES_PORT:-}" ]; then
    # more intuitive to see in the process list what is going on
    #export PGPORT="$POSTGRES_PORT"
    opts="$opts -p $POSTGRES_PORT"
fi

POSTGRES_USER="${PGUSER:-${POSTGRESQL_USER:-${POSTGRES_USER:-${USER:-}}}}"
if [ -n "${POSTGRES_USER:-}" ]; then
    # more intuitive to see in the process list what is going on
    #export PGUSER="$POSTGRES_USER"
    opts="$opts -U $POSTGRES_USER"
fi

POSTGRES_PASSWORD="${PGPASSWORD:-${POSTGRESQL_PASSWORD:-${POSTGRES_PASSWORD:-${PASSWORD:-}}}}"
if [ -n "${POSTGRES_PASSWORD:-}" ]; then
    # can't do this and wouldn't want to as it'd expose it in the password list
    #opts="$opts -U $POSTGRES_PASSWORD"
    export PGPASSWORD="$POSTGRES_PASSWORD"
fi

POSTGRES_DATABASE="${PGDATABASE:-${POSTGRESQL_DATABASE:-${POSTGRES_DATABASE:-${DATABASE:-}}}}"
if [ -n "${POSTGRES_DATABASE:-}" ]; then
    # more intuitive to see in the process list what is going on
    #export PGDATABASE="$POSTGRES_DATABASE"
    opts="$opts -d $POSTGRES_DATABASE"
fi

# split opts
# shellcheck disable=SC2086
exec psql $opts "$@"
