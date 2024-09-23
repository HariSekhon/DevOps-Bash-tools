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

# Install Deb packages in a forgiving way - useful for installing Perl CPAN and Python PyPI modules that may or may not be available
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
    echo "Installs Debian / Ubuntu deb package lists"
    echo
    echo "Takes a list of deb packages as arguments or via stdin, and for any arguments that are plaintext files, reads the packages from those given files (one package per line)"
    echo
    echo "usage: ${0##*/} <list_of_packages>"
    echo
    exit 3
}

for arg; do
    case "$arg" in
        -*) usage
            ;;
    esac
done

echo "Installing Deb Packages"

export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

#apt="apt"
apt="apt-get"

if ! type "$apt" >/dev/null 2>&1; then
    echo "$apt not found in \$PATH ($PATH), cannot install apt packages!"
    exit 1
fi

opts=""
if [ -f /.dockerenv ]; then
    echo "running inside docker, not installing recommended extra packages unless specified to save space"
    opts="--no-install-recommends"
fi
if is_CI; then
    echo "running in CI quiet mode"
    opts="$opts -q"
    echo
    echo "/etc/apt/sources.list:"
    cat /etc/apt/sources.list || :
    echo
    for x in /etc/apt/sources.list.d/*; do
        [ -f "$x" ] || continue
        echo "$x:"
        cat "$x"
        echo
    done
fi
#if is_semmle; then
#    # sudo: no tty present and no askpass program specified
#    echo "Semmle detected, not running package installs as this is a docker user environment without sudo privs or tty"
#    exit 0
#fi

packages=""

process_args(){
    for arg; do
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

echo
echo "Packages to be installed:"
echo
echo "$packages" | tr ' ' '\n'
echo

# requires fuser which might not already be installed, catch-22 situation if wanting to use this for everything including bootstraps
#"$srcdir/apt_wait.sh"

# sudo set in lib/utils-bourne.sh
# want splitting of $opts
# shellcheck disable=SC2154,SC2086
[ -n "${NO_UPDATE:-}" ] || $sudo "$apt" $opts update

if [ -n "${NO_FAIL:-}" ]; then
    # shellcheck disable=SC2086
    for package in $packages; do
        #"$srcdir/apt_wait.sh"
        $sudo "$apt" install -y $opts "$package" || :
    done
else
    #"$srcdir/apt_wait.sh"
    # shellcheck disable=SC2086
    $sudo "$apt" install -y $opts $packages
fi
