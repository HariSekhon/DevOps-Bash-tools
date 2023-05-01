#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:48:29 +0000 (Fri, 15 Feb 2019)
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
. "$srcdir/lib/ci.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/os.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/ruby.sh"

gem="${GEM:-gem}"
opts="${GEM_OPTS:-}"

if type -P "$gem" &>/dev/null; then
    gem="$(type -P "$gem")"
fi

usage(){
    echo "Installs Ruby Gems, taking in to account library paths"
    echo
    echo "Takes a list of ruby gem names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "usage: ${0##*} <list_of_gems>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

gems=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding gems from file:  $arg"
            gems="$gems $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            gems="$gems $arg"
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${gems// }" ]; then
    usage
fi

gems="$(tr ' ' ' \n' <<< "$gems" | sort -u | tr '\n' ' ')"

echo "Installing Ruby Gems"
echo

if is_CI; then
    #echo "running in quiet mode"
    opts="-q"
fi

envopts=""
if is_mac; then
    if type -P brew &>/dev/null; then
        # usually /usr/local
        brew_prefix="$(brew --prefix)"
        # needed to build Crypt::SSLeay
        export OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include"
        export OPENSSL_LIB="$brew_prefix/opt/openssl/lib"
        # need to send OPENSSL_INCLUDE and OPENSSL_LIB through sudo explicitly using prefix
        envopts="OPENSSL_INCLUDE=$OPENSSL_INCLUDE OPENSSL_LIB=$OPENSSL_LIB"
    fi
fi

sudo=""
# don't use --user-install when using RVM because it will cause programs to error out in the RVM environments, breaking builds in Travis CI, Circle CI, AppVeyor etc
if [ $EUID != 0 ] &&
   ! inside_ruby_virtualenv; then
    #sudo=sudo
    opts="$opts --user-install"
fi

echo "$sudo $envopts $gem install $opts $gems"
# want splitting of opts and gems
# shellcheck disable=SC2086
eval $sudo $envopts "$gem" install $opts $gems
