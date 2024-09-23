#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 21:31:10 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Install Apk packages in a forgiving way - useful for installing Perl CPAN and Python PyPI modules that may or may not be available
#
# combine with later use of the following scripts to only build packages that aren't available in the Linux distribution:
#
# perl_cpanm_install_if_absent.sh
# python_pip_install_if_absent.sh

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils-bourne.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/ci.sh"

usage(){
    echo "Installs Alpine APK package lists"
    echo
    echo "Takes a list of apk packages as arguments or via stdin, and for any arguments that are plaintext files, reads the packages from those given files (one package per line)"
    echo
    echo "usage: ${0##*/} <list_of_packages>"
    echo
    exit 3
}

for x in "$@"; do
    case "$x" in
        -*) usage
            ;;
    esac
done

echo "Installing Apk Packages"

packages=""

process_args(){
    for arg in "$@"; do
        if [ -f "$arg" ]; then
            echo "adding packages from file:  $arg"
            packages="$packages $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            packages="$packages $arg"
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

if [ -z "$packages" ]; then
    exit 0
fi

# uniq
packages="$(echo "$packages" | tr ' ' ' \n' | sort -u | tr '\n' ' ')"

echo "Packages to be installed:"
echo
echo "$packages" | tr ' ' '\n'
echo

opts=""
if is_CI; then
    #opts="--quiet"  # doesn't print packages installed but still has a progress bar
    opts="--no-progress"  # prints packages installed but not progress bar filling up logs
fi

# sudo set in lib/utils-bourne.sh
# shellcheck disable=SC2154
[ -n "${NO_UPDATE:-}" ] || $sudo apk update $opts

# [[ ]] and <<< not available in sh
#if echo "$packages" | grep -q openssl-dev; then
#    if apk info | grep -q libressl-dev; then
#        echo "openssl-dev is incompatible with currently installed libressl-dev, trying to uninstall libressl-dev before proceeding..."
#        apk del libressl-dev  # will break if mariadb-dev is installed, this probably isnt't the right place to do this anyway...
#    fi
#fi

if [ -n "${NO_FAIL:-}" ]; then
    for package in $packages; do
        $sudo apk add $opts "$package" || :
    done
else
    # shellcheck disable=SC2086
    $sudo apk add $opts $packages
fi
