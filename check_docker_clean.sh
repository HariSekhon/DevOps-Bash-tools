#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-10-06 00:58:45 +0200 (Fri, 06 Oct 2017)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/docker.sh"

# Caches we want to check have been removed:
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
# .groovy => Groovy
# .ivy    => Ivy (Sbt / Gradle)
# .ivy2
# .m2     => Maven
# .sbt    => SBT

cache_list="
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

if is_inside_docker; then
    for x in $cache_list; do
        for y in /root ~; do
            # This might fail if we're not running as root :-/
            # consider sudo'ing and find / -type d -name $x but that might find .cache under some app or something, although we should probably remove that too
            # for now this is good enough as most dockers are built as root
            # should test for sudo availability as well
            if [ -e "$y/$x" ]; then
                echo "$y/$x detected, should have been removed from docker build"
                exit 1
            fi
        done
    done
    if [ -n "$(find / -type f -name pytools_checks)" ]; then
        echo "pytools_checks detected, should have been removed from docker build"
        exit 1
    fi
fi
