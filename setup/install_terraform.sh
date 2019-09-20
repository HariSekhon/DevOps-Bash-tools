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

# Installs Terraform on Mac

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

TERRAFORM_VERSION="${TERRAFORM_VERSION:-${VERSION:-0.12.9}}"
echo "TERRAFORM_VERSION = $TERRAFORM_VERSION"
echo

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
echo "OS detected as $os"
echo

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

mkdir -pv ~/bin
echo

# common alias mv='mv -i' would force a prompt we don't want, even with -f
unalias mv &>/dev/null || :
mv -fv terraform ~/bin
echo
echo "Please ensure ~/bin is in your \$PATH (automatic is sourcing this repo's .bashrc, which also gives you the 'tf' shortcut alias)"
