#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-09-17 16:27:28 +0100 (Fri, 17 Sep 2021)
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

version="latest"

platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

cd /tmp

date "+%F %T  downloading argocd"
wget -O argocd.$$ "https://github.com/argoproj/argo-cd/releases/$version/download/argocd-$platform-amd64"

date "+%F %T  downloaded argocd"
date "+%F %T  chmod'ing and moving to ~/bin"
chmod +x argocd.$$
mkdir -pv ~/bin
unalias mv &>/dev/null || :
mv -vf argocd.$$ ~/bin/argocd
echo
~/bin/argocd version
