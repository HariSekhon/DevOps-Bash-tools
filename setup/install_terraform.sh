#!/usr/bin/env bash
# args: all
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
srcdir="$(dirname "$0")"

#TERRAFORM_VERSION="${TERRAFORM_VERSION:-${VERSION:-0.12.29}}"
#TERRAFORM_VERSION="${1:-${TERRAFORM_VERSION:-${VERSION:-0.14.5}}}"
TERRAFORM_VERSION="${1:-${TERRAFORM_VERSION:-${VERSION:-1.0.3}}}"

cd /tmp

if [ "$TERRAFORM_VERSION" = all ]; then
    for install_script_version in "$srcdir/"install_terraform[[:digit:]]*.sh; do
        "$install_script_version"
    done
fi

echo "TERRAFORM_VERSION = $TERRAFORM_VERSION"
echo

binary="terraform"
major_version=""
if [ -n "${VERSIONED_INSTALL:-}" ]; then
    major_version="${TERRAFORM_VERSION#0.}"
    major_version="${major_version%%.*}"
    binary="terraform$major_version"
fi

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
echo "OS detected as $os"
echo

if [ -z "${UPDATE_TERRAFORM:-}" ]; then
    # command -v catches aliases, not suitable
    # shellcheck disable=SC2230
    if type -P "$binary" &>/dev/null; then
        echo "Terraform binary '$binary' is already installed and available in \$PATH"
        echo
        echo "To add or overwrite regardless, set the below variable and then re-run this script:"
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

install_path+="/$binary"

# common alias mv='mv -i' would force a prompt we don't want, even with -f
unalias mv &>/dev/null || :
mv -fv terraform "$install_path"
echo
echo "Please ensure $install_path is in your \$PATH"
echo "(this is done automatically if sourcing this repo's .bashrc, which also gives you the 'tf' shortcut alias)"
