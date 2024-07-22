#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-24 11:54:52 +0000 (Tue, 24 Nov 2020)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Quickly determines and downloads latest MySQL JDBC jar or an explicitly given version

Useful to get the jar to upload to data integration 3rd party directories or Docker images or Kubernetes
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

latest="9.0.0"

#version="${1:-8.0.22}"
version="${1:-$latest}"

# TODO: figure out a way of determining what the latest MySQL JDBC connector version is

if [ "$version" = "$latest" ]; then
    download_url="https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-$version.tar.gz"
else
    download_url="https://downloads.mysql.com/archives/get/p/3/file/mysql-connector-j-$version.tar.gz"
fi

timestamp "Downloading MySQL JDBC version '$version' from $download_url"
echo >&2

tarball="mysql-connector-j-$version.tar.gz"

if type -P wget; then
    wget -cO "$tarball" "$download_url"
else
    tmpfile="$(mktemp).tar.gz"
    curl --fail "$download_url" > "$tmpfile"
    unalias mv &>/dev/null || :
    mv -fv "$tmpfile" "$tarball"
fi
tar zxvf "$tarball" -C . --strip 1 "mysql-connector-j-$version/mysql-connector-j-$version.jar"

timestamp "Download complete"
