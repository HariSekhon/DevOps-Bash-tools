#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:48:29 +0000 (Fri, 15 Feb 2019)
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

CPANM="${CPANM:-cpanm}"

usage(){
    echo "Installs Perl CPAN modules using Cpanm, taking in to account library paths, perlbrew envs etc"
    echo
    echo "Takes a list of perl module names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "usage: ${0##*} <list_of_modules>"
    echo
    exit 3
}

cpan_modules=""
for x in "$@"; do
    if [ -f "$x" ]; then
        echo "adding cpan modules from file:  $x"
        cpan_modules="$cpan_modules $(sed 's/#.*//;/^[[:space:]]*$$/d' "$x")"
        echo
    else
        cpan_modules="$cpan_modules $x"
    fi
    cpan_modules="$(tr ' ' ' \n' <<< "$cpan_modules" | sort -u | tr '\n' ' ')"
done

for x in "$@"; do
    case "$1" in
        -*) usage
            ;;
    esac
done

if [ -z "$cpan_modules" ]; then
    usage
fi

echo "Installing CPAN Modules"
echo

opts=""
if [ -n "${TRAVIS:-}" ]; then
    echo "running in quiet mode"
    opts="-q"
fi

envopts=""
if [ "$(uname -s)" = "Darwin" ]; then
    if type -P brew &>/dev/null; then
        # usually /usr/local
        brew_prefix="$(brew --prefix)"
        # needed to build Crypt::SSLeay
        export OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include"
        export OPENSSL_LIB="$brew_prefix/opt/openssl/lib"
        # need to send OPENSSL_INCLUDE and OPENSSL_LIB through sudo explicitly using prefix
        envopts=OPENSSL_INCLUDE="$OPENSSL_INCLUDE OPENSSL_LIB=$OPENSSL_LIB"
    fi
fi

SUDO=""
if [ $EUID != 0 ] &&
   [ -z "${PERLBREW_PERL:-}" ]; then
    SUDO=sudo
fi

echo "$SUDO $envopts $CPANM --notest $opts $cpan_modules"
# want splitting of opts and modules
# shellcheck disable=SC2086
$SUDO $envopts "$CPANM" --notest $opts $cpan_modules
