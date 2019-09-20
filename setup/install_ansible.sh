#!/usr/bin/env bash
#
#  Author: Hari Sekhon
#  Date: 2019/09/20
#
#  https://github.com/harisekhon/devops-bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs Ansible on Mac / Linux
#
# https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

os="$(uname -s)"
echo "OS detected as $os"
echo

sudo=sudo
[ $EUID -eq 0 ] && sudo=""

if [ -z "${UPDATE_ANSIBLE:-}" ]; then
    if command -v ansible &>/dev/null; then
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
    if command -v dnf &>/dev/null; then
        echo "Installing via DNF"
        $sudo dnf install -y ansible
    elif command -v yum &>/dev/null; then
        echo "Installing via Yum"
        $sudo yum install -y ansible
    elif command -v apt &>/dev/null; then
        echo "Installing via APT"
        if grep -q Ubuntu /etc/*release; then
            $sudo apt update
            $sudo apt install software-properties-common
            $sudo apt-add-repository --yes --update ppa:ansible/ansible
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
    elif command -v apk &>/dev/null; then
        echo "Installing via Apk"
        $sudo apk update
        $sudo apk add ansible
    elif command -v emerge &>/dev/null; then
        echo "Installing via Emerge"
        $sudo emerge -av app-admin/ansible
    elif command -v pip &>/dev/null; then
        echo "Installing via Pip"
        pip install --user ansible
    else
        echo "Couldn't find Linux package manager!'"
        exit 1
    fi
elif command -v pip &>/dev/null; then
    echo "Unsupported OS, installing via Pip"
    pip install --user ansible
else
    echo "Unsupported OS and pip not available!"
    exit 2
fi
