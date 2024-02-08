#!/usr/bin/env bash
# shellcheck disable=SC2230
# command -v catches aliases, not suitable
#
#  Author: Hari Sekhon
#  Date: 2019/09/20
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs Ansible on Mac / Linux
#
# https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
#
# Prompts for sudo if using OS system packages
#
# If falling back to Python PIP then if running as root installs to System, otherwise installs to local --user library

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

os="$(uname -s)"
echo "OS detected as $os"
echo

sudo=sudo
pip_opts="--user"
if [ $EUID -eq 0 ]; then
    sudo=""
    pip_opts=""
fi

if [ -z "${UPDATE_ANSIBLE:-}" ]; then
    if type -P ansible &>/dev/null; then
        echo "Ansible already installed"
        echo
        echo "To update ansible, set the below and then re-run this script"
        echo
        echo "export UPDATE_ANSIBLE=1"
        exit 0
    fi
fi

echo "Installing Ansible"
echo
if [ "$os" = "Darwin" ]; then
    brew update
    brew install ansible
elif [ "$os" = "Linux" ]; then
    if type -P dnf &>/dev/null; then
        echo "Installing via DNF"
        $sudo dnf install -y ansible
    elif type -P yum &>/dev/null; then
        echo "Installing via Yum"
        $sudo yum install -y ansible
    elif type -P apt &>/dev/null; then
        echo "Installing via APT"
        if grep -q Ubuntu /etc/*release; then
            $sudo apt update
            $sudo apt install -y software-properties-common
            $sudo apt-add-repository -y --update ppa:ansible/ansible
            $sudo apt update
            $sudo apt install -y ansible
        else
            # assume Debian
            line='deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main'
            if ! grep -Fq "$line" /etc/apt/sources.list; then
                echo "$line" >> /etc/apt/sources.list
            fi
            $sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
            $sudo apt update
            $sudo apt install -y ansible
        fi
    elif type -P apk &>/dev/null; then
        echo "Installing via Apk"
        $sudo apk update
        $sudo apk add ansible
    elif type -P emerge &>/dev/null; then
        echo "Installing via Emerge"
        $sudo emerge -av app-admin/ansible
    elif type -P pip &>/dev/null; then
        echo "Installing via Pip"
        pip install $pip_opts ansible
    else
        echo "Couldn't find Linux package manager!'"
        exit 1
    fi
elif type -P pip &>/dev/null; then
    echo "Unsupported OS, installing via Pip"
    pip install $pip_opts ansible
else
    echo "Unsupported OS and pip not available!"
    exit 2
fi
