#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-10-01 18:51:22 +0900 (Thu, 01 Oct 2026)
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
Empties the Trash portably, whether on Linux or Mac

On macOS, requires granting Full Disk Access to your Terminal application:

    System Settings -> Privacy & Security -> Full Disk Access

This command takes you straight there on macOS 14:

    open 'x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_more_args "$@"

linux_trash=~/.local/share/Trash

if is_mac; then
    timestamp "Emptying Trash on Mac"
    if ! ls -la ~/.Trash/ &>/dev/null; then
        die "ERROR: Terminal does not have Full Disk Access to be able to empty the Trash, see --help"
    fi
    rm -rf ~/.Trash/*
elif is_linux; then
    timestamp "Emptying Trash on Linux"
    if type -P gio &>/dev/null; then
        gio trash --empty
    else
        if ! ls -la "$linux_trash/" &>/dev/null; then
            die "ERROR: permissions error accessing: $linux_trash"
        fi
        rm -rf "$linux_trash"/files/*
        rm -rf "$linux_trash"/info/*
    fi
else
    die "OS Not Supported: must be either Linux or Mac"
fi
timestamp "Trash Emptied"
