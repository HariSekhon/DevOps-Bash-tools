#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-11-06 22:17:22 +0200 (Thu, 06 Nov 2025)
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
Adds an App to auto-start at Login using Applescript

Checks the /Applications and \$HOME/Applications for the given app name

(auto-tries both with and without .app extension so you can provide it either way)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<app>"

help_usage "$@"

num_args 1 "$@"

arg="$1"

HOME="${HOME:-$(cd && pwd)}"

app=""
for path in \
        "/Applications/$arg.app" \
        "/Applications/$arg" \
        "/$HOME/Applications/$arg.app" \
        "/$HOME/Applications/$arg"; do
    if [ -e "$path" ]; then
        timestamp "Found '$arg' at '$path'"
        app="$path"
    fi
done

if [ -z "$app" ]; then
    die "App '$arg' not found in /Applications or $HOME/Applications"
fi

timestamp "Setting '$app' to start at login"
osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app\", hidden:false}"
