#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-21 10:13:38 +0200 (Wed, 21 Aug 2024)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads Azul OpenJDK version for Linux x86_64

If Java version is not specified, automatically determines latest version to download

For Linux distributions, see also this doc to install native packages:

    https://docs.azul.com/core/install/debian
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<java_version>]"

help_usage "$@"

#min_args 1 "$@"

java_version="${1:-}"

if is_mac; then
	grep(){
		command ggrep "$@"
	}
fi

url_base="https://cdn.azul.com/zulu/bin"

timestamp "Fetching directory listing of versions from: $url_base/"
timestamp "(slow, takes 30 seconds due to large listing, please wait)"
directory_listing="$(curl -sS "$url_base/")"

if is_blank "$java_version"; then
    timestamp "Java version not specified, attempting to find latest JDK version"
    # super brittle to pass a web page that will change
    versions="$(grep -P -o 'jdk\K\d+' <<< "$directory_listing" || die "Failed to parse JDK versions out of directory listing")"
    java_version="$(sort -nr <<< "$versions" | head -n1 || :)"
    is_blank "$java_version" && die "Failed to parse JDK version from list of versions"
    timestamp "Determined latest JDK version to be $java_version"
fi

timestamp "Parsing download path from directory listing"
# links are relative
download_paths="$(grep -Eo -e "/zulu/bin/zulu${java_version}[^>]+jdk[^>]+-linux_x64.tar.gz" \
                           -e "/zulu/bin/zulu[^>]+jdk${java_version}[^>]*-linux_x64.tar.gz" \
                           <<< "$directory_listing" |
                  grep -v beta ||
                  die "Failed to parse download URL for version $java_version")"
download_path="$(tail -n1 <<< "$download_paths" | sed 's|/zulu/bin/||')"

download_url="$url_base/$download_path"

timestamp "Downloading $download_url"
wget -c "$download_url"
timestamp "Download complete"
