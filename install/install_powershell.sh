#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-09 22:38:36 +0000 (Mon, 09 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs PowerShell on Mac and various Linux distros
#
# https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

if type -P pwsh &>/dev/null; then
    echo "PowerShell is already installed"
    exit 0
fi

if is_mac; then
    brew cask install powershell
elif is_linux; then
    # Ubuntu 16.04 and 18.04 - 18.10 onwards use Snap, will require updates
    # 16.04 works, 18.04 has broken package dependency
    if grep -q '^DISTRIB_ID=Ubuntu' /etc/*release; then
        "$srcdir/install_powershell_ubuntu.sh"
#        if grep -E '^DISTRIB_RELEASE=(19|18\.10)' /etc/*release; then
#            # assigned in lib
#            # shellcheck disable=SC2154
#            $sudo snap install powershell --classic
#        else
#            version="$(awk -F= '/^DISTRIB_RELEASE=/{print $2}' /etc/*release)"
#            $sudo apt-get update
#            $sudo apt-get install -y wget apt-transport-https
#            wget -q "https://packages.microsoft.com/config/ubuntu/$version/packages-microsoft-prod.deb"
#            $sudo dpkg -i packages-microsoft-prod.deb
#            $sudo apt-get update
#            $sudo apt-get install -y powershell
#        fi
    # works on Debian 8 & 9
    # Debian 10 not supported yet, only in Preview
    # https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7#debian-10
    elif grep -q '^ID=debian' /etc/*release; then
        "$srcdir/install_powershell_debian.sh"
#        # works in Stretch but not in Jessie
#        #codename="$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/*release)"
#        codename="$(grep -Eo '^VERSION="[[:digit:]]* \(.+\)"' /etc/*release | sed 's/.*(//; s/)//; s/"//g')"
#        $sudo apt-get update
#        $sudo apt-get install -y curl gnupg apt-transport-https
#        curl https://packages.microsoft.com/keys/microsoft.asc | $sudo apt-key add -
#        $sudo sh -c "echo 'deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-$codename-prod $codename main' > /etc/apt/sources.list.d/microsoft.list"
#        $sudo apt-get update
#        $sudo apt-get install -y powershell
    elif grep -qi 'redhat' /etc/*release; then
        "$srcdir/install_powershell_rhel.sh"
#        version="$(awk -F= '/^VERSION_ID=/{print $2}' /etc/*release)"
#        version="${version//\"/}"
#        if [ "$version" != 7 ]; then
#            echo "Unsupported RHEL/CentOS version"
#            exit 1
#        fi
#        curl "https://packages.microsoft.com/config/rhel/$version/prod.repo" | $sudo tee /etc/yum.repos.d/microsoft.repo
#        $sudo yum install -y powershell
    else
        echo "Unsupported Linux distribution"
        exit 1
    fi
else
    echo "Unsupported OS"
    exit 1
fi
