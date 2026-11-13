#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-11-14 01:24:47 +0800 (Sat, 14 Nov 2026)
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
Creates a sqlite3 db key cache table entry for a given key

If the key doesn't exist it creates it
If the key already exists it updates it
(Upsert behaviour)

Uses a single table called 'key_cache' which should be pre-existing and
initialized by the adjacent script sqlite_cache_initialize.sh and
the queried by the adjacent script sqlite_cache_get.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<db_filename.sqlite3> <key> <value>"

help_usage "$@"

num_args 3 "$@"

check_bin sqlite3

export SQLITE_HISTORY=/dev/null

db="$1"
key="$2"
value="$3"

if ! [[ "$db" =~ \.sqlite3 ]]; then
    usage "DB name given does not match the expected format: NAME.sqlite3"
fi

if ! [ -f "$db" ]; then
    die "DB file not found: $db"
fi

#key_escaped="${key//\'/\'\'}"
key_hex="$(LC_ALL=C od -An -v -tx1 <<< "$key" | tr -d ' \n')"
value_hex="$(LC_ALL=C od -An -v -tx1 <<< "$value" | tr -d ' \n')"

# pass key and value as hexadecimal to safely handle newlines,
# tabs and other special characters
sqlite3 -init /dev/null \
        -batch \
        -noheader \
        "$db" \
    "
        INSERT INTO key_cache (key, value)
        VALUES (
            CAST(X'$key_hex' AS TEXT),
            CAST(X'$value_hex' AS TEXT)
        )
        ON CONFLICT(key) DO UPDATE SET
            value = excluded.value;
    "
