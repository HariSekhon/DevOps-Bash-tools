#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-10-29 17:38:41 +0100 (Fri, 29 Oct 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(dirname "${BASH_SOURCE[0]}")"

VERSION="${1:-3.7.1}"

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
if [ "$arch" = x86_64 ]; then
    arch="amd64"
fi

cd /tmp
wget -O helm.tar.gz "https://get.helm.sh/helm-v$VERSION-$platform-$arch.tar.gz"

tar zxvf helm.tar.gz

chmod +x "$platform-$arch/helm"
mv -iv "$platform-$arch/helm" ~/bin/
