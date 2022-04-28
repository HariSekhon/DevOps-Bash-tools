#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-18 20:03:00 +0100 (Thu, 18 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Blocking wait on apt-get locks to allow multiple apt-get calls to wait instead of exiting with errors
#
# Not really a new idea, there are similar implementations eg.
#
# https://gist.github.com/tedivm/e11ebfdc25dc1d7935a3d5640a1f1c90

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

sleep_secs=1

locks="
/var/lib/dpkg/lock
/var/lib/apt/lists/lock
"

unattended_upgrade_log="/var/log/unattended-upgrades/unattended-upgrades.log"

sudo=""
[ $EUID = 0 ] || sudo=sudo

check_bin(){
    if ! type -P "$1" &>/dev/null; then
        echo "$1 not found in \$PATH ($PATH)" >&2
        exit 1
    fi
}

check_bin apt-get
check_bin fuser

if [ -n "$sudo" ]; then
    check_bin "$sudo"
fi

while true; do
    for lock in $locks; do
        if $sudo fuser "$lock" &>/dev/null; then
            echo "apt lock in use ($lock), waiting..." >&2
            sleep "$sleep_secs"
            continue 2
        fi
    done
    if [ -f "$unattended_upgrade_log" ] &&
       $sudo fuser "$unattended_upgrade_log" &>/dev/null; then
        echo "apt unattended upgrade log in use ($unattended_upgrade_log), waiting..." >&2
        sleep "$sleep_secs"
        continue
    fi
    break
done
