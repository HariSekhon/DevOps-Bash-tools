#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
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

# shellcheck disable=SC1090
. "$srcdir/../lib/ci.sh"

#if type -P aws &>/dev/null &&
#   type -P sam &>/dev/null &&
#   type -P awless &>/dev/null; then
#    echo "AWS CLI, SAM and awless already installed"
#    exit 0
#fi

echo
echo "Installing AWS CLI tools"
echo

uname_s="$(uname -s)"
mkdir -p ~/bin

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:$HOME/bin"

if type -P aws &>/dev/null; then
    echo "AWS CLI already installed"
else
    echo "Installing AWS CLI"
    PYTHON_USER_INSTALL=1 "$srcdir/../python_pip_install.sh" awscli
    echo
fi

"$srcdir/install_eksctl.sh"

if type -P ecs-cli &>/dev/null; then
    echo "ECS CLI already installed"
else
    echo "Installing AWS ECS CLI"
    if [ "$uname_s" = Darwin ]; then
        wget -O ~/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-darwin-amd64-latest
    else
        wget -O ~/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
    fi
    chmod +x ~/bin/ecs-cli
fi

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

if type -P awless &>/dev/null; then
    echo "Awless already installed"
else
    echo
    echo "=========================="
    echo "Awless is unmaintained now, installing only optimistically and ignoring failures..."
    echo "=========================="
    echo
    set +e
    echo "Installing AWLess"
    if [ "$uname_s" = Darwin ]; then
        # this brew install fails on Linux even when brew is installed and works for SAM CLI
        brew tap wallix/awless
        echo
        brew install awless
    else
        if ! curl -sS https://updates.awless.io >/dev/null; then
            #echo
            #echo "AWLess SSL certificate still expired, must install manually until fixed"
            "$srcdir/getawless.sh"
        else
            curl -sS https://raw.githubusercontent.com/wallix/awless/master/getawless.sh | bash
        fi
        mv -iv awless ~/bin/
    fi
fi

# AWS CLI usually installs to ~/.local/bin/aws on Linux or ~/Library/Python/2.7/bin on Mac
#
# AWS SAM CLI command installs to the standard HomeBrew directory
#
# On Mac that will be /usr/local/bin/sam
# On Linux it will be /home/linuxbrew/.linuxbrew/bin for root or ~/.linuxbrew/bin for users
#
# Awless is usually installed to /usr/local/bin/awless

cat <<EOF

Done

Installed locations:

$(type -P aws)
$(type -P ecs-cli)
$(type -P eksctl)
$(type -P sam)
$(type -P awless)

EOF
