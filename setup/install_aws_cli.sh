#!/usr/bin/env bash
# shellcheck disable=SC2230
# command -v catches aliases, not suitable
#
#  Author: Hari Sekhon
#  Date: 2019-09-19 11:26:11
#  (moved from Makefile)
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs AWS CLI & SAM CLI

# You might need to first:
#
# yum install -y epel-release
# yum install -y gcc git make python-pip which
#
# this is automatically done first when called via 'make aws' at top level of this repo

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

if type -P aws &>/dev/null && type -P sam &>/dev/null; then
    echo "AWS CLI & SAM already installed"
    exit 0
fi

echo "Installing AWS CLI & SAM CLI"
echo

PYTHON_USER_INSTALL=1 "$srcdir/../python_pip_install.sh" awscli
echo

"$srcdir/install_homebrew.sh"
echo

#if [ -z "${HOME:-}" ]; then
#    echo "\$HOME is unset, must set to run this"
#    exit 1
#fi

#if [ -d "$HOME/.linuxbrew/bin" ]; then
#    export PATH="$PATH:$HOME/.linuxbrew/bin"
#fi

if [ -d ~/.linuxbrew/bin ]; then
    export PATH="$PATH:"~/.linuxbrew/bin
fi

brew tap aws/tap
echo

brew install aws-sam-cli
