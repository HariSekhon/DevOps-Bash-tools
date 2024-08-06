#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-28 17:39:13 +0100 (Tue, 28 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Removes local caches for OS package installations and Programming Language development libraries
#
# Useful in Docker builds to reduce image size or just general space cleaning
#
# eg.
#
# Add this to the end of each of your RUN statements in your Dockerfile to clean up the installation caches and not save them in the Docker layer:
#
#   curl -s https://raw.githubusercontent.com/HariSekhon/bash-tools/master/bin/clean_caches.sh | sh
#

set -eu  #o pipefail
[ -n "${DEBUG:-}" ] && set -x
# not using any of my libraries or path dependencies to allow the above self-contained curl to shell to work for calling from Dockerfiles
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# https://wiki.alpinelinux.org/wiki/Local_APK_cache

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

if [ -z "${GOPATH-}" ]; then
    if [ -d ~/go ]; then
        GOPATH=~/go
    else
        GOPATH="notfound"  # to avoid deleting root level dirs which might be something else
    fi
fi

#  ~/.groovy/grapes
personal_cache_list="
.cache
.cpan
.cpanm
.gem
.gradle
.groovy
go/pkg
go/src/golang.org
go/src/github.com
$GOPATH/pkg
$GOPATH/src/golang.org
$GOPATH/src/github.com
.ivy
.ivy2
.m2
.sbt
Library/Caches/Homebrew
"


echo "Deleting Caches"
# =====================================
# Run native OS cache cleaning commands
#
# rm -fr is done in the next block
#if type apk >/dev/null 2>&1 2>&1; then
#    rm -rf -- /var/cache/apk
if type apt-get >/dev/null 2>&1; then
    # could accidentally remove things it shouldn't
    #apt-get autoremove -y
    echo "* apt-get clean"
    apt-get clean
elif type yum >/dev/null 2>&1; then
    # could accidentally remove things it shouldn't
    #yum autoremove -y
    echo "* yum clean all"
    yum clean all
elif type brew >/dev/null 2>&1; then
    brew cleanup
fi

echo "Deleting OS Caches"
# =========================
# Delete OS Cache locations
#
# safer than for loop - don't risk word splitting with rm
echo "$cache_list" |
while read -r directory; do
    [ -n "$directory" ] || continue
    [ -e "$directory" ] || continue
    echo "* removing $directory"
    rm -rf -- "$directory" || :
    [ -e "$directory" ] || continue
    # shellcheck disable=SC2039
    if [ "${EUID:-${UID:-$(id -u)}}" != 0 ]; then
        if type sudo >/dev/null 2>&1; then
            sudo -n rm -rf -- "$directory"
        fi
    fi
done

echo "Deleting Personal Caches"
# =============================================================
# Delete Personal Cache locations & Programming Language Caches
#
echo "$personal_cache_list" |
while read -r directory; do
    [ -n "$directory" ] || continue
    # posix sh, not as nice as bash but want to use this script from Alpine docker builds
    if [ "$(echo "$directory" | cut -c1)" = / ]; then
        user_home_cache="$directory"
    else
        user_home_cache=~/"$directory"
    fi
    [ -e "$user_home_cache" ] || continue
    echo "* removing $user_home_cache"
    # ~ more reliable than $HOME which could be unset
    rm -rf -- "$user_home_cache" || :
    # shellcheck disable=SC2039
    if [ "${EUID:-${UID:-$(id -u)}}" != 0 ]; then
        if type sudo >/dev/null 2>&1; then
            # in case user home directory is owned by root, do a late stage removal as root
            sudo -n rm -rf -- "$user_home_cache"
            [ -e "/root/$directory" ] || continue
            echo "* removing /root/$directory"
            sudo -n rm -rf -- "/root/$directory"
        fi
    fi
done

echo "Finished deleting caches"
