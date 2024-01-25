#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-05 15:41:31 +0000 (Wed, 05 Jan 2022)
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
Downloads and unpacks OpenJDK to \$PWD

Print the JAVA_HOME you need
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

#min_args 1 "$@"

version="${1:-11.0.11+9}"

os="$(get_os)"
arch="$(get_arch)"

# AdoptOpenJDK deviate from the common terms
if [ "$os" = darwin ]; then
    os="mac"
fi
if [ "$arch" = amd64 ]; then
    arch="x64"
fi

#version="$("$srcdir/../urlencode.sh" <<< "$version")"
version2="$(tr '+' '_' <<< "$version")"
url="https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-$version/OpenJDK11U-jdk_${arch}_${os}_hotspot_${version2}.tar.gz"

timestamp "Downloading JDK version '$version'"
echo
download "$url"
echo

target_dir="${PWD:-$(pwd)}/jdk-$version"
if is_mac; then
    target_dir+="/Contents/Home"
fi

if [ -d "$target_dir" ]; then
    timestamp "Target directory already exists, aborting"
else
    timestamp "Extracting tarball"
    echo
    tar xvf "${url##*/}"
fi
echo

timestamp "Done"
echo
cat <<EOF

Set your environment as follows:

export JAVA_HOME="$target_dir"
export PATH="\$PATH:\$JAVA_HOME/bin"

EOF
