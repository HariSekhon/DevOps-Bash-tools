#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-04-15 23:58:48 +0200 (Wed, 15 Apr 2026)
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
Assigns a new random mac address to your network interface

If no interface is specified, defaults to eth0

This can be useful:

- to reduce tracking of your computer on a local network
- for network testing of gateway behaviours
- to test switch port security against unassigned mac addresses being used on ports or mac spoofing

Tested on Linux

Doesn't work on newer Macs which result in this error:

    ifconfig: ioctl (SIOCAIFADDR): Can't assign requested address
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<interface>]"

help_usage "$@"

max_args 1 "$@"

interface="${1:-eth0}"

timestamp "Generating new random MAC address"
new_mac_address="$(
    openssl rand -hex 6 |
    sed '
        s/\(..\)/\1:/g;
        s/:$//
    '
)"
timestamp "Generated new random MAC address: $new_mac_address"

timestamp "Assigning new random MAC address to interface: $interface"

# If it's the wifi interface en0, disable it first and then re-enable it
# Mac wifi may need to be switched off first - but newer macs don't allow you to explicit set mac address anyway
#if [ "$interface" = en0 ]; then
    # sudo is automatically set in lib/utils.sh
    # shellcheck disable=SC2154
    #
#    $sudo networksetup -setairportpower en0 off
#fi

if is_mac; then
    $sudo ifconfig "$interface" ether "$new_mac_address"
    #
    # results on this due to restrictions on newer Macs:
    #
    #   ifconfig: ioctl (SIOCAIFADDR): Can't assign requested address
    #
elif is_linux; then
    $sudo ifconfig "$interface" hw ether "$new_mac_address"
else
    die "Error: Unsupported OS - only written for Linux or Mac"
fi

# if it's the wifi interface en0, disable it first and then re-enable it
#if [ "$interface" = en0 ]; then
#    $sudo networksetup -setairportpower en0 on
#fi

timestamp "Done"
