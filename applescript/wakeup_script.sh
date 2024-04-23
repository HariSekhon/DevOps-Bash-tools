#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-04-17 22:26:11 +0400 (Wed, 17 Apr 2024)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Script of actions to run whenever a Mac wakes up from sleep

Currently this script just flushes the DNS cache to fix Chrome hitting ERR_NOT_FOUND errors when waking up on a VPN

To set this up, edit the path to this script in the plist xml file and then load it:

    cp -fv $srcdir/com.harisekhon.wakeup_script.plist ~/Library/LaunchAgents/
    launchctl load $srcdir/com.harisekhon.wakeup_script.plist
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

{

timestamp "Running Mac wake up script: $0"

timestamp "Flushing DNS cache"
dscacheutil -flushcache

timestamp "Reloading mDNSResponder"
sudo killall -HUP mDNSResponder

timestamp "Wake up script completed"
echo

} 2>&1 | tee -a "$srcdir/wakeup_script.log"
