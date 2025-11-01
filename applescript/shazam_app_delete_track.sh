#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-02 00:22:03 +0300 (Sun, 02 Nov 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Deletes a single track from the local Mac's Shazam app sqlite database

The Shazam app caches this while running so you will need to quit and re-open the app to see this change
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args='"<artist>" "<track>"'

help_usage "$@"

num_args 2 "$@"

mac_only

artist="$1"
track="$2"

dbpath="$(
    find ~/Library/Group\ Containers \
        -type f \
        -path '*/*group.com.shazam/com.shazam.mac.Shazam/ShazamDataModel.sqlite' 2>/dev/null |
    head -n 1
    )"

if [ -z "$dbpath" ]; then
    die "Error: Could not locate ShazamDataModel.sqlite"
fi

timestamp "Found Shazam App DB: $dbpath"

timestamp "Backing up DB before deleting"
backup="${dbpath}.bak.$(date +%Y%m%d%H%M%S)"
cp -v "$dbpath" "$backup"
timestamp "Backup created at $backup"
echo >&2

# Delete from ZSHTAGRESULTMO using JOIN with ZSHARTISTMO
sqlite3 -batch "$dbpath" <<EOF
DELETE FROM ZSHTAGRESULTMO
WHERE Z_PK IN (
    SELECT r.Z_PK
    FROM ZSHTAGRESULTMO r
    JOIN ZSHARTISTMO a ON a.ZTAGRESULT = r.Z_PK
    WHERE a.ZNAME = '$artist' AND r.ZTRACKNAME = '$track'
);
EOF

timestamp "Deleting track from DB: '$artist - $track'"
timestamp "You must now quit and re-open the Shazam app to pick up this change"
