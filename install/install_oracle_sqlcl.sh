#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-13 00:59:42 +0300 (Sun, 13 Oct 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Downloads the latest Oracle SQLcl command line client to /usr/local/ and links it to /usr/local/bin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

timestamp "Installing Oracle SQLcl command line client"
echo

# sometimes on Mac /usr/local is writeable by the user, in which case don't enforce sudo
if ! [ -w /usr/local ] || ! [ -w /usr/local/bin ]; then
#if ! am_root; then
    die "ERROR: must be root to run this script as it will download and unpack to /usr/local"
fi

# permalink to latest release
download_url="https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip"

timestamp "Downloading: $download_url"
wget -c "$download_url"
echo

timestamp "Unzipping to /usr/local/"
unzip -n sqlcl-latest.zip -d /usr/local/
echo

# clashes with GNU parallel which installs an 'sql' program in the path so link this to sqlcl to avoid path priority clashes
#if ! [ -e /usr/local/bin/sql ]; then
#    timestamp "Linking /usr/local/sqlcl/bin/sql to /usr/local/bin/ for \$PATH convenience"
#    ln -sv /usr/local/sqlcl/bin/sql /usr/local/bin/
#    echo
#fi

if ! [ -e /usr/local/bin/sqlcl ]; then
    timestamp "Linking /usr/local/sqlcl/bin/sql to /usr/local/bin/sqlcl for \$PATH convenience"
    ln -sv /usr/local/sqlcl/bin/sql /usr/local/bin/sqlcl
    echo
fi

timestamp "Completed installation of SQLcl oracle client"
#echo
#timestamp "Don't forget to add /usr/local/sqlcl/bin to your \$PATH and check for clashes with other programs called 'sql' in your path (GNU Parallels puts one in /usr/local/bin/ for example)"
