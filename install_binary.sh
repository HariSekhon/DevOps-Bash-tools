#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: 'https://s3.amazonaws.com/cloudbees-core-cli/master/cloudbees-{os}-{arch}.tar.gz' cloudbees
#
#  Author: Hari Sekhon
#  Date: 2022-01-05 11:25:17 +0000 (Wed, 05 Jan 2022)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads and installs a binary from a given URL and extraction path to /usr/local/bin if run as root or ~/bin if run as user

The URL can be parameterized with {os} and {arch} tokens to be replaced by the current OS (linux/darwin) or Architecture (amd64/arm)

If a zip or tarball is given, will be unpacked in /tmp and the binary path specified will be copied to bin

An optional binary destination can be given to name the file - if the file name is an absolute path will place it there instead of /usr/local/bin or ~/bin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<url> [<binary_path_in_zip_or_tarball> <binary_destination_name>]"

help_usage "$@"

min_args 1 "$@"

url="$1"

os="$(get_os)"
arch="$(get_arch)"

url="${url//\{os\}/$os}"
url="${url//\{arch\}/$arch}"

package="${url##*/}"
download_file="/tmp/$package.$$"

if [[ "$package" =~ \.zip$ ]] || has_tarball_extension "$package"; then
    if [ $# -lt 2 ]; then
        usage "binary file path must be specified if downloading a tarball or zip file ('$package')"
    fi
    binary="$2"
fi

timestamp "Downloading"
download "$url" "$download_file"

if has_tarball_extension "$package"; then
    timestamp "Extracting package"
    if has_tarball_gzip_extension "$package"; then
        tar xvzf "$download_file"
    elif has_tarball_bzip2_extension "$package"; then
        tar xvjf "$download_file"
    fi
    if ! [ -f "$binary" ]; then
        die "Failed to extract binary '$binary' from '$download_file'"
    fi
    download_file="$binary"
    echo
fi

timestamp "Setting executable"
chmod +x "$download_file"
echo

destination="${3:-${download_file##*/}}"

if ! [[ "$destination" =~ ^/ ]]; then
    if [ $EUID = 0 ]; then
        destination="/usr/local/bin/$destination"
    else
        destination=~/bin/"$destination"
    fi
fi

timestamp "Moving to bin"
unalias mv &>/dev/null || :
mv -fv "$download_file" "$destination"
echo

timestamp "Installation complete"
