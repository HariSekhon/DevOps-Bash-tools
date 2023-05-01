#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: 'https://s3.amazonaws.com/cloudbees-core-cli/master/cloudbees-{os}-{arch}.tar.gz' cloudbees
#
#  Author: Hari Sekhon
#  Date: 2022-01-05 11:25:17 +0000 (Wed, 05 Jan 2022)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads and installs a binary from a given URL and extraction path to /usr/local/bin if run as root or ~/bin if run as user

The URL can be parameterized with {os} and {arch} tokens to be replaced by the current OS (linux/darwin) or Architecture (amd64/arm)

Environment overrides for {os} and {arch} if their values are Darwin, Linux, x86_64 or i386 respectively, in this order of priority:

export OS_DARWIN=macOS    # because some packages use 'macOS' while others use 'darwin'
export OS_LINUX=Linux     # because some packages titlecase this

export ARCH_X86_64=amd64  # because some packages use 'amd64' instead of 'x86_64'
export ARCH_X86=x86       # because some packages use 'x86' instead of 'i386'
export ARCH_ARM64=ARM64   # because some packages use uppercase 'ARM64' instead of 'arm64'
export ARCH_ARM=ARM       # because some packages use uppercase 'ARM' instead of 'arm'
export ARCH_OVERRIDE=all  # because some packages use a random universal arch rather than 'x86_64' or 'i386'

If a zip or tarball is given, will be unpacked in /tmp and the binary path specified will be copied to bin

An optional binary destination can be given to name the file - if the file name is an absolute path will place it there instead of /usr/local/bin or ~/bin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<url> [<binary_path_in_zip_or_tarball> <install_path>]"

help_usage "$@"

min_args 1 "$@"

url="$1"

os="$(get_os)"
arch="$(get_arch)"

url="${url//\{os\}/$os}"
url="${url//\{arch\}/$arch}"

package="${url##*/}"
tmp="/tmp/install_binary.$$"
download_file="$tmp/$package"

if [[ "$package" =~ \.zip$ ]] || has_tarball_extension "$package"; then
    if [ $# -lt 2 ]; then
        usage "binary file path must be specified if downloading a tarball or zip file ('$package')"
    fi
    binary="$2"
    binary="${binary//\{os\}/$os}"
    binary="${binary//\{arch\}/$arch}"
fi

mkdir -p -v "$tmp"

trap_cmd "rm -f -- '$download_file'"

cd "$tmp"

timestamp "Downloading: $url"
download "$url" "$download_file"

if has_tarball_extension "$package"; then
    timestamp "Extracting tarball package"
    if ! type -P tar &>/dev/null; then
        "$srcdir/install_packages.sh" tar
    fi
    if has_tarball_gzip_extension "$package"; then
        tar xvzf "$download_file"
    elif has_tarball_bzip2_extension "$package"; then
        tar xvjf "$download_file"
    fi
    if ! [ -f "$binary" ]; then
        die "Failed to find binary '$binary' in unpacked tarball '$download_file' - is the given binary filename / path correct?"
    fi
    download_file="$binary"
    echo
elif [[ "$package" =~ \.zip$ ]]; then
    timestamp "Extracting zip package"
    if ! type -P unzip &>/dev/null; then
        "$srcdir/install_packages.sh" unzip
    fi
    unzip -o "$download_file"
    if ! [ -f "$binary" ]; then
        die "Failed to find binary '$binary' in unpacked zip '$download_file' - is the given binary filename / path correct?"
    fi
    download_file="$binary"
fi

timestamp "Setting executable: $download_file"
chmod +x "$download_file"
echo

destination="${3:-${2:+${2##*/}}}"
if [ -z "$destination" ]; then
    destination="${download_file##*/}"
    # no longer suffixing with $$, used in $tmp instead
    #destination="${destination%%.$$}"
    # if there are any -darwin-amd64 or -amd64-darwin suffixes remove them either way around (this is why $os is stripped before and after)
    destination="${destination%%-$os}"
    destination="${destination%%_$os}"
    destination="${destination%%-$arch}"
    destination="${destination%%_$arch}"
    destination="${destination%%-x86_64}"  # $arch is amd64, we must check to strip this explicitly extra
    destination="${destination%%_x86_64}"
    destination="${destination%%-$os}"
    destination="${destination%%_$os}"
fi

if ! [[ "$destination" =~ ^/ ]]; then
    if am_root || [ -w /usr/local/bin ]; then
        destination="/usr/local/bin/$destination"
    else
        destination=~/bin/"$destination"
    fi
fi
install_path="${destination%/*}"
if [ -e "$install_path" ] && ! [ -d "$install_path" ]; then
    die "ERROR: install path $install_path is not a directory, aborting!"
fi
mkdir -p -v "$install_path"
#echo

timestamp "Moving to install dir:"
# common alias mv='mv -i' would force a prompt we don't want, even with -f
unalias mv &>/dev/null || :
mv -fv -- "$download_file" "$destination"
echo

timestamp "Installation complete"

if [ -n "${RUN_VERSION_ARG:-}" ]; then
    echo
    "$destination" version
elif [ -n "${RUN_VERSION_OPT:-}" ]; then
    echo
    "$destination" --version
fi
