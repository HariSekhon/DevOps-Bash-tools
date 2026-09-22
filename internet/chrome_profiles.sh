#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-09-23 05:10:47 +0900 (Wed, 23 Sep 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
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
Lists the folders and names of Chrome profiles to be passed to the chrome command when using automation like chrome.sh
multi-url stdin staggered opening

Uses jq to parse the Chrome local state, attempts to install jq if not present using whichever package manager
is available

Written for Linux and Mac
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

if is_mac; then
    chrome_local_state="$HOME/Library/Application Support/Google/Chrome/Local State"
elif is_linux; then
    chrome_local_state="${XDG_CONFIG_HOME:-$HOME/.config}/google-chrome/Local State"
else
   usage "Unsupported OS - only written for Linux and Mac"
fi

if ! type -P jq &>/dev/null; then
    "$srcdir/../packages/install_packages_if_absent.sh" jq
fi

jq -r '
    .profile.info_cache |
    to_entries[] |
    "\(.key)\t\(.value.name)"
' \
"$chrome_local_state" |
column -t -s $'\t'
