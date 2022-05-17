#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-19 11:26:11
#  (moved from Makefile)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs AWS SAM CLI

# You might need to first:
#
# yum install -y epel-release
# yum install -y gcc git make python-pip which
#
# this is automatically done first when called via 'make aws' at top level of this repo

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/ci.sh"

section "Installing AWS SAM CLI"

mkdir -p ~/bin

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:$HOME/bin"

if grep -q Alpine /etc/os-release 2>/dev/null; then
    echo "Skipping SAM CLI install on Alpine as Homebrew installer is broken on Alpine, see https://github.com/Homebrew/homebrew-core/issues/49813"
    exit 0
fi

if grep -q 'CentOS release [1-6][\.[:space:]]' /etc/system-release 2>/dev/null; then
    echo "Skipping SAM CLI install on RHEL/CentOS < 7 as Homebrew installer no longer supports it, see https://github.com/Homebrew/brew/issues/7583#issuecomment-640379742"
    exit 0
fi

if is_CI && ! type -P brew && ! is_curl_min_version 7.41; then
    echo "Skipping SAM CLI install due to curl version < 7.41 - HomeBrew won't install, which AWS SAM CLI depends on, so skipping to avoid breaking older CI builds..."
    exit 0
fi

# when installing homebrew this doesn't detect the missing directory so doesn't add it to path, and after homebrew this needs to be called again
load_homebrew_path(){
    local directory
    # root installs to first one, user installs to the latter
    for directory in /home/linuxbrew/.linuxbrew/bin ~/.linuxbrew/bin; do
        if [ -d "$directory" ]; then
            export PATH="$PATH:$directory"
        fi
    done
}

load_homebrew_path

if type -P sam &>/dev/null; then
    echo "AWS SAM CLI already installed"
else
    # installs on Linux too as it is the AWS recommended method to install SAM CLI
    "$srcdir/install_homebrew.sh"
    load_homebrew_path
    echo

    echo "Installing AWS SAM CLI"
    # AWS installs SAM CLI the same way on Linux + Mac
    brew tap aws/tap
    echo
    # ignore this failure:
    # ==> Downloading https://api.github.com/repos/aws/aws-sam-cli/tarball/v1.3.1
    # ==> Downloading from https://codeload.github.com/aws/aws-sam-cli/legacy.tar.gz/v
    # curl: (22) The requested URL returned error: 404 Not Found
    set +e
    brew install aws-sam-cli
fi

# AWS SAM CLI command installs to the standard HomeBrew directory
#
# On Mac that will be /usr/local/bin/sam
# On Linux it will be /home/linuxbrew/.linuxbrew/bin for root or ~/.linuxbrew/bin for users

cat <<EOF

Done

Installed to:

$(type -P sam)

EOF
