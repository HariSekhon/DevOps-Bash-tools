#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-03-01 22:49:15 +0000 (Fri, 01 Mar 2024)
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
Takes snapshots of before and after clipboard changes and diffs them to show config changes

Takes an initial snapshot to /tmp

Then prompts for you to copy changes to the clipboard (eg. via UI changes and Configuration-as-Code copy)

Then takes another snapshot and diffs the two

Example Use Case:

Jenkins to backport settings to JCasC

    1. copy the existing JCasC config from here to clipboard:

        \$JENKINS_URL/manage/configuration-as-code/viewExport

    2. run this script to save that clipboard to a file

    3. then when prompted, reconfigure Jenkins in the UI

    4. copy the new JCasC config from the page above to the clipboard

    5. press enter to tell this script to continue to past the new clipboard to another file and diff for you
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

before_snapshot_txt="/tmp/paste_diff_settings.txt.$$"
after_snapshot_txt="/tmp/paste_diff_settings.txt.$$"

timestamp "Pasting clipboard to $before_snapshot_txt"
"$srcdir/paste_from_clipboard.sh" > "$before_snapshot_txt"
echo >&2

timestamp 'Now make your changes and copy your new config to clipboard'
echo >&2

read -r -p 'Press Enter when finished to take another snapshot and diff them'
echo >&2

timestamp "Pasting snapshot to $after_snapshot_txt"
"$srcdir/paste_from_clipboard.sh" > "$after_snapshot_txt"
echo >&2

echo "Diff:" >&2
echo >&2

diff -w "$before_snapshot_txt" "$after_snapshot_txt" &&
echo "No changes"
