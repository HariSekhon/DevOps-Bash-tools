#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-06 10:37:29 +0000 (Fri, 06 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Tries to installs Python snakebite module for Python 3 or Python 2 downgrading each time to try another version

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$srcdir/../python/python_pip_install.sh" "snakebite-py3[kerberos]" ||
"$srcdir/../python/python_pip_install.sh" "snakebite-py3" ||
"$srcdir/../python/python_pip_install.sh" "snakebite[kerberos]" ||
"$srcdir/../python/python_pip_install.sh" "snakebite"
