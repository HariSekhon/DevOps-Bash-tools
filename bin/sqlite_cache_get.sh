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
Searches a sqlite3 db key cache table for a given key

Assumes a single table called 'key_cache',
created by the adjacent script sqlite_cache_initialize.sh
and populated from the related script sqlite_cache_set.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<db_filename.sqlite3> <key>"

help_usage "$@"

num_args 2 "$@"

check_bin sqlite3

export SQLITE_HISTORY=/dev/null

db="$1"
key="$2"

if ! [[ "$db" =~ \.sqlite3 ]]; then
    usage "DB name given does not match the expected format: NAME.sqlite3"
fi

if ! [ -f "$db" ]; then
    die "DB file not found: $db"
fi

#key_escaped="${key//\'/\'\'}"
key_hex="$(LC_ALL=C od -An -v -tx1 <<< "$key" | tr -d ' \n')"

# retrieve value as hexadecimal to safely handle newlines,
# tabs and other special characters
hex_value="$(
    sqlite3 -init /dev/null \
            -batch \
            -noheader \
            "$db" \
    "
        SELECT hex(value)
        FROM key_cache
        WHERE key = CAST(X'$key_hex' AS TEXT)
        LIMIT 1;
    "
)"

[ -n "$hex_value" ] || die "Failed to retrieve cache key: $key"

# decode hexadecimal without losing trailing newlines
escaped=""
for ((i = 0; i < ${#hex_value}; i += 2)); do
    byte=${hex_value:i:2}
    escaped+="\\x$byte"
done

printf '%b' "$escaped"
