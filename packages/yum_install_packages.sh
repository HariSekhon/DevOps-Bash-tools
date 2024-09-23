#!/usr/bin/env bash
# shellcheck disable=SC2230
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

# Install RPM packages in a forgiving way - useful for installing Perl CPAN and Python PyPI modules that may or may not be available
#
# combine with later use of the following scripts to only build packages that aren't available in the Linux distribution:
#
# perl_cpanm_install_if_absent.sh
# python_pip_install_if_absent.sh

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

usage(){
    echo "Installs Yum RPM package lists"
    echo
    echo "Takes a list of yum packages as arguments or via stdin, and for any arguments that are plaintext files, reads the packages from those given files (one package per line)"
    echo
    echo "usage: ${0##/*} <list_of_packages>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

packages=""

process_args(){
    for arg; do
        if [ -f "$arg" ]; then  # && file "$arg" | grep -q ASCII  # file not available by default and may not be installed
            echo "adding packages from file:  $arg"
            packages="$packages $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
            echo
        else
            packages="$packages $arg"
        fi
        # uniq
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

echo "Installing RPM Packages"

if [ -z "${packages// }" ]; then
    exit 0
fi

packages="$(echo "$packages" | tr ' ' ' \n' | sort -u | sed '/^[[:space:]]*$/d')"

# RHEL8 ruining things with no default python and lots of python package renames
# - handling systematically rather than exploding out all my repos package lists
if [ -n "${NO_FAIL:-}" ]; then
    if grep -q '^REDHAT_SUPPORT_PRODUCT_VERSION="8"' /etc/*release 2>/dev/null; then
        if grep -q 'python-' <<< "$packages"; then
            # shellcheck disable=SC2001
            packages="$packages
$(sed 's/^python-/python2-/' <<< "$packages")
$(sed 's/^python-/python3-/' <<< "$packages")
$(sed 's/^python[23]-/python2-/' <<< "$packages")
$(sed 's/^python[23]-/python3-/' <<< "$packages")"
            echo "Expanding Python packages out to: $packages"
        fi
    fi
fi

# CentOS is EOL - but for some reason CentOS 7 works without this, while CentOS 6 and 8 need archive
if grep -qi 'NAME=.*CentOS' /etc/*release && grep -q '^VERSION="[68]"$' /etc/*release; then
    echo "CentOS EOL detected, replacing yum base URL to vault to re-enable package installs"
    sed -i 's/^[[:space:]]*mirrorlist/#mirrorlist/' /etc/yum.repos.d/CentOS-*
    sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|' /etc/yum.repos.d/CentOS-*
fi

echo
echo "Packages to be installed:"
echo
tr ' ' '\n' <<< "$packages"
echo

if [ -n "${NO_FAIL:-}" ]; then
    if type -P dnf &>/dev/null; then
        # dnf exits if any of the packages aren't found so do them individually and ignore failures
        for package in $packages; do
            # sudo set in lib/utils-bourne.sh
            # shellcheck disable=SC2154
            rpm -q "$package" || $sudo dnf install -y "$package" || :
        done
    else
        # shellcheck disable=SC2086
        $sudo yum install -y $packages || :
    fi
else
    # dnf exists with a proper error code on any error so faster to do all packages together
    if type -P dnf &>/dev/null; then
        # want splitting
        # shellcheck disable=SC2086
        dnf install -y $packages
    else
        # must install separately to check install succeeded because yum install returns 0 when some packages installed and others didn't
        for package in $packages; do
            rpm -q "$package" || $sudo yum install -y "$package"
        done
    fi
fi
