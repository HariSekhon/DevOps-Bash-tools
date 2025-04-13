#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-04-14 04:30:02 +0800 (Mon, 14 Apr 2025)
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
Does a recursive deep search for Mac Time Machine excluded paths on individual file/folder attributes
to find items excluded from backups that don't appear in the Time Machine UI

If a path argument is given, does the deep scan on only that tree

See HariSekhon/Knowledge-Base Mac page for more details on Time Machine path exclusions for why this is needed:

    https://github.com/HariSekhon/Knowledge-Base/blob/main/mac.md#time-machine
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<path>]"

help_usage "$@"

#min_args 1 "$@"

path="${1:-/}"

timestamp "sudo mdfind \"com_apple_backup_excludeItem = 'com.apple.backupd'\""
echo >&2
sudo mdfind "com_apple_backup_excludeItem = 'com.apple.backupd'" |
sort
echo >&2

timestamp "defaults read /Library/Preferences/com.apple.TimeMachine.plist ExcludeByPath"
echo >&2
defaults read /Library/Preferences/com.apple.TimeMachine.plist ExcludeByPath |
sed '
    s/^(//;
    s/)$//;
    s/^[[:space:]]*//;
    s/^"//;
    s/",*$//;
    /^[[:space:]]*$/d;
' |
sort
echo >&2

timestamp "defaults read /Library/Preferences/com.apple.TimeMachine SkipPaths"
echo >&2
defaults read /Library/Preferences/com.apple.TimeMachine SkipPaths |
sed '
    s/^(//;
    s/)$//;
    s/^[[:space:]]*//;
    s/^"//;
    s/",*$//;
    /^[[:space:]]*$/d;
' |
sort
echo >&2

timestamp "Doing deep search for xattr excluded paths on each file / directory (this will take a very long time)"
sudo find "$path" |
while read -r path; do
    if sudo xattr -p com.apple.metadata:com_apple_backup_excludeItem "$path" &>/dev/null; then
        echo "$path"
    fi
done
