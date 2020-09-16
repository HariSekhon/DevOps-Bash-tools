#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-16 08:11:53 +0100 (Wed, 16 Sep 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://jenkins-x.io/docs/install-setup/install-binary/

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ -z "${FORCE:-}" ] && type -P jx &>/dev/null; then
    echo "jx is already available in \$PATH, skipping"
    exit 0
fi

cd /tmp

latest_version="$(curl -sS "https://github.com/jenkins-x/jx/releases/latest" | sed 's#.*tag/\(.*\)\".*#\1#')"
platform="$(uname -s)"

date "+%F %T  downloading jx"
wget -qcO jx.tgz "https://github.com/jenkins-x/jx/releases/download/$latest_version/jx-$platform-amd64.tar.gz"
date "+%F %T  downloaded jx"

date "+%F %T  unpacking jx"
tar xzvf jx.tgz jx

date "+%F %T  chmod'ing and moving to ~/bin"
chmod +x jx

mkdir -pv ~/bin
unalias mv &>/dev/null || :
mv -vf jx ~/bin/

~/bin/jx version --short
