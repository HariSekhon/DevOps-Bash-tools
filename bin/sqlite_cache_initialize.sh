#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-11-14 01:04:41 +0800 (Sat, 14 Nov 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
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
Creates a sqlite3 db key cache table in the given db filename

The table is just called 'key_cache' and is optimized for key cache lookups

Designed for use with the adjacent scripts:

    sqlite_cache_get.sh
    sqlite_cache_set.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<db_filename.sqlite3> <key>"

help_usage "$@"

num_args 1 "$@"

check_bin sqlite3

export SQLITE_HISTORY=/dev/null

db="$1"

if ! [[ "$db" =~ \.sqlite3 ]]; then
    usage "DB name given does not match the expected format: NAME.sqlite3"
fi

#if ! [ -f "$db" ]; then
#    die "DB file not found: $db"
#fi

# PRIMARY KEY    - creates primary key index with unique key constraint and an index for fast lookups
# COLLATE BINARY - exact, case-sensitive matching
# WITHOUT ROWID  - optimises storage for a table with a primary key
#                  since we have no use for row IDs in key cache use case
# IF NOT EXISTS  - safe to run repeatedly idempotently by only creating the table
#                  if it doesn't already exist, thereby avoiding errors
sqlite3 -init /dev/null "$db" "
    CREATE TABLE IF NOT EXISTS key_cache (
        key   TEXT NOT NULL PRIMARY KEY COLLATE BINARY,
        value TEXT NOT NULL
    ) WITHOUT ROWID;
"
