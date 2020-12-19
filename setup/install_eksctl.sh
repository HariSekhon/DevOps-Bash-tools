#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
# shellcheck disable=SC2230
# command -v catches aliases, not suitable
#
#  Author: Hari Sekhon
#  Date: 2020-12-11 11:59:42 +0000 (Fri, 11 Dec 2020)
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs AWS eksctl from WeaveWorks

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:$HOME/bin"

if type -P eksctl &>/dev/null; then
    echo "AWS eksctl already installed"
    exit 0
fi

echo "Installing AWS eksctl tool"
echo

uname_s="$(uname -s)"

mkdir -p ~/bin

if [ "$uname_s" = Darwin ]; then
    "$srcdir/install_homebrew.sh"
    brew tap weaveworks/tap
    brew install weaveworks/tap/eksctl
    brew upgrade eksctl
    brew link --overwrite eksctl
else
    echo "downloading eksctl binary"
    curl -sSL --fail "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    echo "moving eksctl to $HOME/bin"
    mv /tmp/eksctl ~/bin
fi

echo "Installed"
echo
echo -n "eksctl version:  "
eksctl version

echo
echo
"$srcdir/install_kubectl.sh"
