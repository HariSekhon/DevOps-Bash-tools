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

# Installs AWS CLI, eksctl and ECS CLI

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

section "Installing AWS CLI"

mkdir -p ~/bin

# unreliable that HOME is set, ensure shell evaluates to the right thing before we use it
[ -n "${HOME:-}" ] || HOME=~

export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:$HOME/bin"

#if type -P aws &>/dev/null; then
#    echo "AWS CLI already installed"
if type -P apk &>/dev/null; then
    if ! grep -q 'https://dl-cdn.alpinelinux.org/alpine/edge/testing' /etc/apk/repositories; then
        echo -e -n "\n@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
    fi
    apk add aws-cli-v2@testing --no-cache
else
    echo "Installing AWS CLI"
    # old AWS CLI v1 - doesn't support AWS SSO
    #PYTHON_USER_INSTALL=1 "$srcdir/../python/python_pip_install.sh" awscli
    pushd /tmp
    #curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    #wget -c "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
    #unzip -o awscli-bundle.zip
    # needs to find Python 3 first in the path to work
    #PATH="/usr/local/opt/python/libexec/bin:$PATH" ./awscli-bundle/install -b ~/bin/aws
    if is_mac; then
        wget -c "https://awscli.amazonaws.com/AWSCLIV2.pkg" -O "AWSCLIV2.pkg"
        # defined in utils.sh lib
        # shellcheck disable=SC2154
        $sudo installer -pkg AWSCLIV2.pkg -target /
        rm -fr -- AWSCLIV2.pkg
    else
        wget -c "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip"
        unzip -o awscliv2.zip
        # defined in utils.sh lib
        # shellcheck disable=SC2154
        $sudo ./aws/install --update
        rm -fr -- aws awscliv2.zip
    fi
    popd
    echo
    echo -n "AWS CLI version: "
    aws --version
    echo
fi

"$srcdir/install_eksctl.sh"

if type -P ecs-cli &>/dev/null; then
    echo "ECS CLI already installed"
else
    echo "Installing AWS ECS CLI"
    if is_mac; then
        wget -O ~/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-darwin-amd64-latest
    else
        wget -O ~/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
    fi
    chmod +x ~/bin/ecs-cli
fi

# AWS CLI usually installs to ~/.local/bin/aws on Linux or ~/Library/Python/2.7/bin on Mac

cat <<EOF

Done

Installed locations:

$(type -P aws)
$(type -P ecs-cli)
$(type -P eksctl)

EOF
