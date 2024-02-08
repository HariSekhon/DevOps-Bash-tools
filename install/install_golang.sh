#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-01-03 19:13:35 +0000 (Sun, 03 Jan 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Downloads Golang to ~/bin

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

version="${1:-1.15.6}"

install_location=~/bin

uname_s="$(uname -s | tr '[:upper:]' '[:lower:]')"

tmp_tar="$(mktemp)"

url="https://golang.org/dl/go$version.$uname_s-amd64.tar.gz"

mkdir -p -v "$install_location"

echo "$(date '+%F %T')  Downloading $url"
wget -cqO "$tmp_tar" "$url"

echo "$(date '+%F %T')  Unpacking to $install_location"
tar zxf "$tmp_tar" -C "$install_location"

echo
echo "Golang installed to $install_location"
echo
echo "To make use of it set the following:"
echo
echo "export PATH=\"$install_location/go/bin:\$PATH\""
echo "export GOROOT=\"$install_location/go\""
