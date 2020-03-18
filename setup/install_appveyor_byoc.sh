#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-09 22:38:36 +0000 (Mon, 09 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs PowerShell on Mac and various Linux distros
#
# https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

if ! type -P pwsh &>/dev/null; then
    "$srcdir/install_powershell.sh"
fi

# leading whitespace break PowerShell commands
pwsh << EOF
Install-Module AppVeyorBYOC -Scope CurrentUser -Force; Import-Module AppVeyorBYOC
EOF

# AppVeyor host dependencies
# sysvinit-tools on RHEL, but appveyor byoc looks for dpkg so is probably only compatible with debian based distributions
if grep -qi 'debian|ubuntu' /etc/*release; then
    "$srcdir/install_packages.sh" libcap2-bin libterm-ui-perl sudo sysvinit-utils
fi
