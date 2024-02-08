#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-23 22:30:21 +0100 (Mon, 23 Sep 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Installs diff-so-fancy on Mac and Linux
#
# .bashrc will detect and use diff-so-fancy if it is available in the $PATH,
# by setting $GIT_PAGER
#
# ~/.gitconfig will take precedence though if a pager is explicitly specified there

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if type -P diff-so-fancy &>/dev/null; then
    echo "diff-so-fancy is already installed!"
    exit 0
fi

if [ "$(uname -s)" = Darwin ]; then
    if ! type -P brew &>/dev/null; then
        "$srcdir/install_homebrew.sh"
    fi
    brew update
    brew install diff-so-fancy
else
#     if [ "$(uname -s)" = Linux ]; then
#         if ! type -P npm &>/dev/null; then
#           if type -P dnf &>/dev/null; then
#               dnf install -y npm
#           elif type -P yum &>/dev/null; then
#               yum install -y npm
#           elif type -P apt-get &>/dev/null; then
#               # not available on Debian yet it seems, but present on Ubuntu
#               apt-get update
#               apt-get install -y npm
#           elif type -P apk &>/dev/null; then
#               apk update
#               apk add npm
#           fi
#       fi
#   fi
    # Not using NPM as it is broken on both CentOS and Ubuntu
    #
    # https://github.com/so-fancy/diff-so-fancy/issues/350
    #
    # # npm install diff-so-fancy
    # /
    # └── diff-so-fancy@1.2.7
    #
    # npm WARN enoent ENOENT: no such file or directory, open '/package.json'
    # npm WARN !invalid#1 No description
    # npm WARN !invalid#1 No repository field.
    # npm WARN !invalid#1 No README data
    # npm WARN !invalid#1 No license field.
    #
    #if type -P npm &>/dev/null; then
    #    npm install diff-so-fancy
    #else
        echo "Downloading diff-so-fancy fatpack to ~/bin"
        mkdir -pv ~/bin
        cd ~bin
        wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
        chmod +x diff-so-fancy
    #fi
fi
