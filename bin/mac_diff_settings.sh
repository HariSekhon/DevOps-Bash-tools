#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-02-16 14:45:38 +0000 (Fri, 16 Feb 2024)
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
Takes snapshots of before and after a settings change to find which 'defaults write' settings

to use in $srcdir/../settings/mac_settings.sh

Takes an initial snapshot to /tmp

Then prompts for you to change the settings in the UI

Then takes another snapshot and diffs the two
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

if ! is_mac; then
    die "Only macOS is supported"
fi

before_snapshot_txt="/tmp/macos_defaults_before.txt.$$"
after_snapshot_txt="/tmp/macos_defaults_after.txt.$$"

timestamp "Taking snapshot to $before_snapshot_txt"
defaults read > "$before_snapshot_txt"
echo >&2

timestamp 'Now change your mac settings in the UI settings'
echo >&2

read -r -p 'Press Enter when finished to take another snapshot and diff them'
echo >&2

timestamp "Taking snapshot to $after_snapshot_txt"
defaults read > "$after_snapshot_txt"
echo >&2

echo "Diff:" >&2
echo >&2

diff -w "$before_snapshot_txt" "$after_snapshot_txt" &&
echo "No changes"
