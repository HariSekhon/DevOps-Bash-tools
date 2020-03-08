#!/bin/sh
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 21:31:10 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Install Deb packages in a forgiving way - useful for installing Perl CPAN and Python PyPI modules that may or may not be available
#
# combine with later use of the following scripts to only build packages that aren't available in the Linux distribution:
#
# perl_cpanm_install_if_absent.sh
# python_pip_install_if_absent.sh

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/ci.sh"

usage(){
    echo "Installs Debian / Ubuntu deb package lists"
    echo
    echo "Takes a list of deb packages as arguments or .txt files containing lists of packages (one per line)"
    echo
    echo "usage: ${0##*} <list_of_packages>"
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
    cat /etc/apt/sources.list
    echo
    for x in /etc/apt/sources.list.d/*; do
        [ -f "$x" ] || continue
        echo "$x:"
        cat "$x"
        echo
    done
    # workaround to broken repos
    # W: An error occurred during the signature verification. The repository is not updated and the previous index files will be used. GPG error: https://downloads.apache.org/cassandra/debian 311x InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY E91335D77E3E87CB
    # W: GPG error: http://dl.yarnpkg.com/debian stable Release: The following signatures were invalid: KEYEXPIRED 1507181400  KEYEXPIRED 1546376218  KEYEXPIRED 1546372003  KEYEXPIRED 1580619281  KEYEXPIRED 1580607983  KEYEXPIRED 1580619281  KEYEXPIRED 1507181400  KEYEXPIRED 1546376218  KEYEXPIRED 1546372003  KEYEXPIRED 1580619281  KEYEXPIRED 1580607983  KEYEXPIRED 1507181400  KEYEXPIRED 1546376218  KEYEXPIRED 1546372003  KEYEXPIRED 1580619281  KEYEXPIRED 1580607983
    # E: The repository 'http://dl.yarnpkg.com/debian stable Release' is no longer signed.
    # bash-tools/Makefile.in:272: recipe for target 'apt-packages' failed
    if is_shippable_ci; then
        rm -fv /etc/apt/sources.list.d/cassandra.sources.list*
        rm -fv /etc/apt/sources.list.d/yarn.list*
    fi
    # workaround for:
    # Some packages could not be installed. This may mean that you have
    # requested an impossible situation or if you are using the unstable
    # distribution that some required packages have not yet been created
    # or been moved out of Incoming.
    # The following information may help to resolve the situation:
    #
    # The following packages have unmet dependencies:
    #  mssql-server : Depends: libsasl2-modules-gssapi-mit but it is not going to be installed
    #  E: Error, pkgProblemResolver::Resolve generated breaks, this may be caused by held packages.
    #  bash-tools/Makefile.in:272: recipe for target 'apt-packages' failed
    #  make[2]: *** [apt-packages] Error 123
    #  make[2]: Leaving directory '/home/appveyor/projects/pylib'
    #  bash-tools/Makefile.in:212: recipe for target 'system-packages' failed
    if is_appveyor; then
        sed -i '/https:\/\/packages.microsoft.com\/ubuntu\/.*\/mssql-server/d'
    fi
fi

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

if [ -n "${*:-}" ]; then
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

SUDO=""
# $EUID is not defined in posix sh
# shellcheck disable=SC2039
[ "${EUID:-$(id -u)}" != 0 ] && SUDO=sudo

# shellcheck disable=SC2086
[ -n "${NO_UPDATE:-}" ] || $SUDO "$apt" $opts update

if [ -n "${NO_FAIL:-}" ]; then
    # shellcheck disable=SC2086
    for package in $packages; do
        $SUDO "$apt" install -y $opts "$package" || :
    done
else
    # shellcheck disable=SC2086
    $SUDO "$apt" install -y $opts $packages
fi
