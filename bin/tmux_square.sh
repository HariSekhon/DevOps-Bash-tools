#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-05-14 05:27:20 +0300 (Wed, 14 May 2025)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback to help steer this or other code I publish
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
Launches tmux and runs the commands given as args in a square tiled view

Fast way to launch a bunch of commands in an easily reviewable way

If args aren't given, launches a \$SHELL in each pane, defaulting to bash if \$SHELL is not set

Autogenerates a new session name in the form of \$PWD-\$epoch for uniqueness

Example:

    ${0##*/} htop 'iostat 1' 'ping google.com'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args='"<command_1>" "<command_2>" "<command_3>" "<command_4>"'

help_usage "$@"

max_args 4 "$@"

pwd="${PWD:-$(pwd)}"
epoch="$(date +%s)"

# cannot separate the session name with a dot as this breaks:
#
#   tmux has-session -t "$session"
#
# this command:
#
#   tmux has-session -t /Users/hari/mydir.1747191485
#
# results in this:
#
#   can't find window: /Users/hari/mydir
#
session="$pwd-$epoch"

shell="${SHELL:-bash}"

cmd1="${1:-$shell}"
cmd2="${2:-$shell}"
cmd3="${3:-$shell}"
cmd4="${4:-$shell}"

shift || :

timestamp "Starting new tmux session in detached mode called '$session' with command: $cmd1"
tmux new-session -d -s "$session" "$cmd1"

if ! tmux has-session -t "$session"; then
    die "ERROR: tmux session exited too soon from first command: $cmd1"
fi

for cmd in "$cmd2" "$cmd3" "$cmd4"; do
    timestamp "Splitting the tmux window vertically and launching command: $cmd"
    tmux split-window -h -t "$session":0 "$cmd"
done

timestamp "Balancing the tmux pane layout into a square tiled view for tmux session: $session"
tmux select-layout -t "$session":0 tiled

timestamp "Attaching to tmux session: $session"
tmux attach-session -t "$session"
