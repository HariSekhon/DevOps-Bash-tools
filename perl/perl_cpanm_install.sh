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
. "$srcdir/lib/perl.sh"

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

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

cpan_modules=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then
            echo "adding cpan modules from file:  $arg"
            cpan_modules="$cpan_modules $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            cpan_modules="$cpan_modules $arg"
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "${cpan_modules// }" ]; then
    usage
fi

cpan_modules="$(tr ' ' ' \n' <<< "$cpan_modules" | sort -u | tr '\n' ' ')"

echo "Installing CPAN Modules"
echo

opts="${CPANM_OPTS:-}"
if is_CI; then
    echo "running in quiet mode for CI to minimize log noise"
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
        envopts="OPENSSL_INCLUDE=$OPENSSL_INCLUDE OPENSSL_LIB=$OPENSSL_LIB"
    fi

    # auto CPATH fix for compiling XS modules with Mac's EXTERN.h
    #
    # solves this:
    #
    # ./xshelper.h:34:10: fatal error: 'EXTERN.h' file not found
    # #include <EXTERN.h>
    #          ^~~~~~~~~~
    # 1 error generated.
    #
    for directory in /Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk/System/Library/Perl/"$PERL_MAJOR_VERSION"/darwin-thread-multi-2level; do
        if [ -f "$directory/CORE/EXTERN.h" ]; then
            export CPATH="${CPATH:-}:$directory/CORE"
        fi
    done
    if [ -n "${CPATH:-}" ]; then
        envopts="${envopts} CPATH=$CPATH"
    fi
fi

sudo=""
if [ -n "${PERL_USER_INSTALL:-}" ] ||
   [ -n "${PERLBREW_PERL:-}" ] ||
   [ -n "${GOOGLE_CLOUD_SHELL:-}" ]; then
    sudo=""
elif [ $EUID != 0 ]; then
    sudo=sudo
fi

if [ -n "${NO_FAIL:-}" ]; then
    for cpan_module in $cpan_modules; do
        echo "$sudo $envopts $CPANM --notest $opts $cpan_module"
        # want splitting of opts
        # shellcheck disable=SC2086
        # 'env' prevent a command not found error if sudo isn't used from the space OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include" prefix
        env $sudo $envopts "$CPANM" --notest $opts "$cpan_module" || :
    done
else
    echo "$sudo $envopts $CPANM --notest $opts $cpan_modules"
    # want splitting of opts and modules
    # shellcheck disable=SC2086
    # 'env' prevent a command not found error if sudo isn't used from the space OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include" prefix
    if ! env $sudo $envopts "$CPANM" --notest $opts $cpan_modules; then
        echo
        echo "reading latest cpanm build.log for details:"
        echo
        set +o pipefail
        $sudo find ~/.cpanm/work -type f -name build.log -print0 | xargs -0 ls -tr | tail -n1 | xargs $sudo cat
        # build log is still in user's home dir even when using sudo
        find ~/.cpanm/work -type f -name build.log -print0 | xargs -0 ls -tr | tail -n1 | xargs cat
        exit 1
    fi
fi
