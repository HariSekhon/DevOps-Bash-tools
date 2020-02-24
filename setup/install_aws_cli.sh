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

#if type -P aws &>/dev/null &&
#   type -P sam &>/dev/null &&
#   type -P awless &>/dev/null; then
#    echo "AWS CLI, SAM and awless already installed"
#    exit 0
#fi

echo "Installing AWS CLI tools"
echo

uname_s="$(uname -s)"
mkdir -p ~/bin

export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:$HOME/bin"

if type -P aws &>/dev/null; then
    echo "AWS CLI already installed"
else
    echo "Installing AWS CLI"
    PYTHON_USER_INSTALL=1 "$srcdir/../python_pip_install.sh" awscli
    echo
fi

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

if grep Alpine /etc/os-release &>/dev/null; then
    echo "Skipping SAM CLI install on Alpine as Homebrew installer is broken on Alpine, see https://github.com/Homebrew/homebrew-core/issues/49813"
    exit 0
fi

# installs on Linux too as it is the AWS recommended method to install SAM CLI
"$srcdir/install_homebrew.sh"
echo

# root installs to first one, user installs to the latter
for x in /home/linuxbrew/.linuxbrew/bin ~/.linuxbrew/bin; do
    if [ -d "$x" ]; then
        export PATH="$PATH:$x"
    fi
done

if type -P sam &>/dev/null; then
    echo "AWS SAM CLI already installed"
else
    echo "Installing AWS SAM CLI"
    # AWS installs SAM CLI the same way on Linux + Mac
    brew tap aws/tap
    echo
    brew install aws-sam-cli
    echo
fi

echo "=========================="
echo "Awless is unmaintained now, installing only optimistically and ignoring failures..."
echo "=========================="
set +e

if type -P awless &>/dev/null; then
    echo "Awless already installed"
else
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
$(type -P sam)
$(type -P awless)

EOF
