#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-28 15:47:41 +0100 (Tue, 28 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
#. "$srcdir/bash-tools/lib/utils.sh"

export PATH="$srcdir:$srcdir/..:$PATH"

if type -P yum &>/dev/null; then
    # RHEL / CentOS does the right thing and pulls in the current version
    #java
    #java-headless
    install_packages.sh java-headless  # won't install to $PATH, make sure to add /usr/lib/jvm/jre/bin/ to $PATH (jre is a symlink)
elif type -P apt-get &>/dev/null; then
    # Debian / Ubuntu
    #openjdk-8-jre-headless  # smaller than openjdk-11 package (127 vs 200 MB) and more tested
    #openjdk-11-jre-headless
    install_packages.sh openjdk-11-jre-headless
elif type -P apk &>/dev/null; then
    # Alpine
    #openjdk8-jre
    #openjdk9-jre-headless
    #openjdk10-jre-headless
    #openjdk11-jre-headless
    install_packages.sh openjdk8-jre
fi
