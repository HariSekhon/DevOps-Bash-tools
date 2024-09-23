#!/usr/bin/env bash
#  shellcheck disable=SC2086
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

# Mac OSX - HomeBrew install packages in a forgiving way

set -eu #o pipefail  # undefined in /bin/sh
[ -n "${DEBUG:-}" ] && set -x

usage(){
    echo "Installs Mac Homebrew package lists"
    echo
    echo "Takes a list of brew packages as arguments or .txt files containing lists of packages (one per line)"
    echo
    echo "usage: ${0##*} <list_of_packages>"
    echo
    exit 3
}

for x in "$@"; do
    case "$x" in
        -*) usage
            ;;
    esac
done

echo "Installing Mac HomeBrew Packages"

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
        if [ -z "${TAP:-}" ]; then
            # uniq
            packages="$(echo "$packages" | tr ' ' ' \n' | sort -u | tr '\n' ' ')"
        fi
    done
}

if [ $# -gt 0 ]; then
    process_args "$@"
else
    # shellcheck disable=SC2046
    process_args $(cat)
fi

# Sudo is not required as running Homebrew as root is extremely dangerous and no longer supported as
# Homebrew does not drop privileges on installation you would be giving all build scripts full access to your system

brew_update_opts=""
if [ -n "${TRAVIS:-}" ]; then
    brew_update_opts="-v"
fi
if [ -z "${NO_UPDATE:-}" ]; then
    if [ -n "${NO_FAIL:-}" ]; then
        set +e #o pipefail  # undefined in /bin/sh
    fi
    echo "Updating Homebrew"
    # brew update takes a long time and doesn't output anything so background it and output progress dots every 5 secs
    # to make sure Travis CI doesn't terminate the job for lack of output activity after 10 mins (used to fail builds)
    brew update $brew_update_opts &
    while jobs | grep -Eq '[[:space:]]+Running[[:space:]]+brew[[:space:]]+update'; do
        # /bin/sh doesn't support -e
        #echo -n .
        printf .
        sleep 5
    done
    set -e #o pipefail  # undefined in /bin/sh
fi

if [ -n "${TAP:-}" ]; then
    # convert to array
    # need splitting
    # shellcheck disable=SC2206
    packages_array=($packages)
    if [ -n "${NO_FAIL:-}" ]; then
        set +e
    fi
    for((i=0; i < ${#packages_array[@]}; i+=2)); do
        tap="${packages_array[$i]}"
        package="${packages_array[(($i+1))]}"
        brew tap "$tap"
        brew install "$package"
    done
    exit
else
    packages="$(tr ' ' '\n' <<< "$packages" | sort -u | tr '\n' ' ')"
fi

opts=""
if [ -n "${CASK:-}" ]; then
    opts="--cask"
fi

echo
echo "Packages to be installed:"
echo
tr ' ' '\n' <<< "$packages"
echo

# Fails if any of the packages are already installed, so you'll probably want to ignore and continue and detect missing
# package later in build system if it's a problem eg. resulting in missing headers later in build
if [ -n "${NO_FAIL:-}" ]; then
    for package in $packages; do
        brew install $opts "$package" || :
    done
else
    # want splitting
    # shellcheck disable=SC2086
    brew install $opts $packages
fi
