#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-03-06 03:25:58 +0000 (Wed, 06 Mar 2024)
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
Downloads and sets up the Debian Netboot Install PXE to /private/tftpboot on Mac

Arch arg defaults to amd64 is not specified

Complete TFP Solution:

1. Run this script

2. download TftpServer to easily GUI start the macOS built-in tftpd server and you're good to go

3. start ISC DHCP server pointing to this machine


See this page for more info:

    https://github.com/HariSekhon/Knowledge-Base/blob/main/dhcp.md
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<arch>]"

help_usage "$@"

#min_args 1 "$@"

arch="${1:-amd64}"

if ! is_mac; then
    die "This is only supported on Mac at this time"
fi

dir="/private/tftpboot"

sudo mkdir -p -v "$dir"

sudo chown -v "$USER" "$dir"

cd "$dir"

# Adapted from here:
#
#   https://wiki.debian.org/PXEBootInstall

mirror=deb.debian.org # A CDN backed by cloudflare and fastly currently
#arch=amd64
#arch=i386
#arch="$(get_arch)"  # we are booting in an x86_64 VM, let it be $1 arg to script to override
dist=stable

wget "http://$mirror/debian/dists/$dist/main/installer-$arch/current/images/netboot/netboot.tar.gz"
wget "http://$mirror/debian/dists/$dist/main/installer-$arch/current/images/SHA256SUMS"
wget "http://$mirror/debian/dists/$dist/Release"
wget "http://$mirror/debian/dists/$dist/Release.gpg"

sha256sum -c <(awk '/netboot\/netboot.tar.gz/{print $1 " netboot.tar.gz"}' SHA256SUMS)
# netboot.tar.gz: OK


sha256sum -c <(awk '/[a-f0-9]{64}[[:space:]].*main\/installer-'"$arch"'\/current\/images\/SHA256SUMS/{print $1 " SHA256SUMS"}' Release)
# SHA256SUMS: OK

#gpg --verify Release.gpg Release

tar zxvf netboot.tar.gz
