#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-28 17:39:13 +0100 (Tue, 28 Apr 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Removes local caches for OS package installations and Programming Language development libraries
#
# Useful in Docker builds to reduce image size or just general space cleaning
#
# eg.
#
# Add this to the end of each of your RUN statements in your Dockerfile to clean up the installation caches and not save them in the Docker layer:
#
#   curl -s https://raw.githubusercontent.com/HariSekhon/bash-tools/master/clean_caches.sh | sh
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
# not using any of myl libraries or path dependencies to allow the above self-contained curl to shell to work for calling from Dockerfile
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# OS package management caches
cache_list="
/etc/apk/cache
/var/lib/apt/lists
/var/cache/apt
/var/cache/apk
/var/cache/yum
"

# Personal Language Caches we want to remove to save space:
#
# .cache => Python pip
#
# .cpan  => Perl
# .cpanm
#
# .gem   => Ruby
#
# Java / Scala / Groovy:
#
# .gradle => Gradle
# .groovy => Groovy (contains grapes/)
# .ivy    => Ivy (Sbt / Gradle)
# .ivy2
# .m2     => Maven
# .sbt    => SBT

personal_cache_list="
.cache
.cpan
.cpanm
.gem
.gradle
.groovy
.ivy
.ivy2
.m2
.sbt
"


echo "Deleting Caches"
# =====================================
# Run native OS cache cleaning commands
#
# rm -fr is done in the next block
#if type -P apk &>/dev/null; then
#    rm -rf /var/cache/apk
if type -P apt-get &>/dev/null; then
    # could accidentally remove things it shouldn't
    #apt-get autoremove -y
    apt-get clean
elif type -P yum &>/dev/null; then
    # could accidentally remove things it shouldn't
    #yum autoremove -y
    yum clean all
fi

# =========================
# Delete OS Cache locations
#
# safer than for loop - don't risk word splitting with rm
while read -r directory; do
    [ -n "$directory" ] || continue
    rm -rf "$directory"
done <<< "$cache_list"

echo "Deleting Personal Caches"
# =============================================================
# Delete Personal Cache locations & Programming Language Caches
#
while read -r directory; do
    [ -n "$directory" ] || continue
    # ~ more reliable than $HOME which could be unset
    rm -rf ~/"$directory"
    if [ $EUID != 0 ]; then
        if type -P sudo &>/dev/null; then
            sudo -n rm -rf "/root/$directory"
        fi
    fi
done <<< "$personal_cache_list"

echo "Finished deleting caches"
