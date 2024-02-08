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

# Installs PowerShell on Ubuntu
#
# https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

sudo=""
[ $EUID -eq 0 ] || sudo=sudo

if type -P pwsh &>/dev/null; then
    echo "PowerShell is already installed"
    exit 0
fi

if ! grep -qi 'redhat' /etc/*release; then
    echo "Not RHEL / CentOS"
    exit 1
fi

version="$(awk -F= '/^VERSION_ID=/{print $2}' /etc/*release)"
version="${version//\"/}"

if [ "$version" != 7 ]; then
    echo "Unsupported RHEL/CentOS version"
    exit 1
fi

curl "https://packages.microsoft.com/config/rhel/$version/prod.repo" | $sudo tee /etc/yum.repos.d/microsoft.repo

$sudo yum install -y powershell
