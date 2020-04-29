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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# OS package management caches
cache_list="
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

# safer than for loop - don't risk word splitting with rm
while read -r directory; do
    [ -n "$directory" ] || continue
    rm -rf "$directory"
done <<< "$cache_list"

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
