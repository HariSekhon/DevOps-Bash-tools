#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-06-02 17:43:35 +0100 (Tue, 02 Jun 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Designed to bootstrap all CI systems with retries to make sure the networking, package lists and package repos works before proceeding
#
# Minimizes CI build failures due to temporary networking blips, which happens more often than you would think when you have a large number of CI builds across a lot of disparate systems

set -eu
[ -n "${DEBUG:-}" ] && set -x

max_tries=10
interval=60 # secs

sudo=""
# EUID undefined in posix sh
#[ $EUID = 0 ] || sudo=sudo
[ "$(whoami)" = root ] || sudo=sudo

retry(){
    # no local in posix sh
    count=0
    while true; do
        # no let or bare (()) in posix sh, must discard output rather than execute it
        _=$((count+=1))
        printf "%s  try %d:  " "$(date '+%F %T')" "$count"
        echo "$*"
        "$@" &&
        break;
        echo
        if [ "$count" -ge "$max_tries" ]; then
            echo "$count tries failed, aborting..."
            exit 1
        fi
        echo "sleeping for $interval secs before retrying"
        sleep "$interval"
        echo
    done
}

if [ "$(uname -s)" = Darwin ]; then
    echo "Bootstrapping Mac"
    # removing adjacent dependency to be able to curl from github to avoid submodule circular dependency (git / submodule / install git & make)
    #retry "$srcdir/../install/install_homebrew.sh"
    if command -v brew 2>&1; then
        # fix for CI runners on Mac with shallow homebrew clone - which is failing all the BuildKite builds
        for git_root in /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask; do
            if [ -d "$git_root" ]; then
                # find out if Homebrew is a shallow git checkout and if so fix it
                if [ -f "$(git -C "$git_root" rev-parse --git-dir)/shallow" ] ||
                   [ "$(git -C "$git_root" rev-parse --is-shallow-repository)" = true ]; then
                    git -C "$git_root" fetch --unshallow
                fi
            fi
        done
        retry brew update
    fi
elif [ "$(uname -s)" = Linux ]; then
    echo "Bootstrapping Linux"
    if type apk >/dev/null 2>&1; then
        retry $sudo apk update
        retry $sudo apk add --no-progress bash git make
    elif type apt-get >/dev/null 2>&1; then
        retry $sudo apt-get update -q
        retry $sudo apt-get install -qy git make
    elif type yum >/dev/null 2>&1; then
        #retry $sudo yum makecache
        retry $sudo yum install -qy git make
    else
        echo "Package Manager not found on Linux, cannot bootstrap"
        exit 1
    fi
else
    echo "Only Mac & Linux are supported for conveniently bootstrapping all install scripts at this time"
    exit 1
fi

#retry make init

# not calling make because in some CI systems we call 'make ci' which includes retries but in others with more restrictive build minutes we only run 'make' for a single shot build
#
#make
