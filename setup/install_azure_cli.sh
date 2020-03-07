#!/usr/bin/env bash
# vim:ts=4:sts=4:sw=4:et
# shellcheck disable=SC2230
# command -v catches aliases, not suitable
#
#  Author: Hari Sekhon
#  Date: 2020-03-06 17:38:12 +0000 (Fri, 06 Mar 2020)
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs Azure CLI

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

echo "Installing Azure CLI"
echo

sudo=""
if [ $EUID != 0 ]; then
    sudo=sudo
    #if ! type -P $sudo &>/dev/null; then
    #    echo "not root and $sudo command not available, skipping Azure CLI install"
    #    exit 0
    #fi
fi

uname_s="$(uname -s)"
#mkdir -p ~/bin

#export PATH="$PATH:/usr/local/bin"
#export PATH="$PATH:$HOME/bin"

install_azure_cli(){
    if type -P apt-get &>/dev/null; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | $sudo bash
    elif type -P yum &>/dev/null; then
        # Needs Python 3
#        if ! type -P python3 &>/dev/null; then
#            echo "Python 3 dependency not found, skipping"
#            exit 0
#        fi
        if ! yum list python3 &>/dev/null; then
            echo "Python 3 not available in package repos, cannot install Azure CLI, skipping..."
            exit 0
        fi
        $sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        $sudo cat > /etc/yum.repos.d/azure-cli.repo <<EOF
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        $sudo yum install -y azure-cli
    elif [ "$uname_s" = Darwin ]; then
        brew install azure-cli
    elif [ "$uname_s" = Linux ]; then
        if type -P apk &>/dev/null; then
            # only works on Alpine 3 - Alpine 2.x doesn't support --no-cache and nor does it have Python 3 package dependency which Azure CLI requires
            apk add --no-cache curl python3 python3-dev alpine-sdk musl-dev libffi-dev openssl-dev
        fi
        yes | curl -L https://aka.ms/InstallAzureCli | bash
    echo
        echo "OS '$uname_s' is not Mac / Linux - not supported"
        exit 1
    fi
}

if type -P az &>/dev/null; then
    echo "Azure CLI already installed"
else
    install_azure_cli
    echo
fi
