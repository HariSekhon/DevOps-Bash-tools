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

# Installs Terraform on Mac / Linux
#
# If running as root, installs to /usr/local/bin
#
# If running as non-root, installs to $HOME/bin

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

TERRAFORM_VERSION="${TERRAFORM_VERSION:-${VERSION:-0.12.29}}"
echo "TERRAFORM_VERSION = $TERRAFORM_VERSION"
echo

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
echo "OS detected as $os"
echo

if [ -z "${UPDATE_TERRAFORM:-}" ]; then
    # command -v catches aliases, not suitable
    # shellcheck disable=SC2230
    if type -P terraform &>/dev/null; then
        echo "Terraform is already installed and available in \$PATH"
        echo
        echo "To update terraform, set the below and then re-run this script"
        echo
        echo "export UPDATE_TERRAFORM=1"
        exit 0
    fi
fi

url="https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_${os}_amd64.zip"

echo "Downloading Terraform from $url"
wget -O terraform.zip "$url"
echo

# stops Zip getting stuck - or use 'unzip -o' (verified switch on Mac OS X and Linux - Alpine / CentOS / Debian / Ubuntu)
#unalias rm
#rm -fv terraform

echo "Unzipping"
unzip -o terraform.zip
echo

if [ $EUID -eq 0 ]; then
    install_path=/usr/local/bin
else
    install_path=~/bin
fi
if [ -e "$install_path" ] && ! [ -d "$install_path" ]; then
    echo "WARNING: install path $install_path is not a directory, aborting!"
    exit 1
fi
mkdir -pv "$install_path"
echo

# common alias mv='mv -i' would force a prompt we don't want, even with -f
unalias mv &>/dev/null || :
mv -fv terraform "$install_path"
echo
echo "Please ensure $install_path is in your \$PATH"
echo "(this is done automatically if sourcing this repo's .bashrc, which also gives you the 'tf' shortcut alias)"
