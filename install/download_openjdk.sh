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
Downloads OpenJDK version for Linux x86_64

If Java version is not specified, automatically determines latest version to download
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

if is_blank "$java_version"; then
    timestamp "Java version not specified, attempting to find latest JDK version"
    # super brittle to pass a web page that will change so just take the first JDK number which is likely to be the production release
    java_version=$(curl -sS "https://jdk.java.net/" | grep -P -o -m 1 'JDK \K\d+')
    timestamp "Determined latest JDK version to be $java_version"
fi

url="https://jdk.java.net/java-se-ri/$java_version"

if [ "$java_version" = 8 ]; then
    url+="-MR6"
elif [ "$java_version" = 11 ]; then
    url+="-MR3"
elif [ "$java_version" = 17 ]; then
    url+="-MR1"
fi

timestamp "Parsing download URL from $url"
download_url="$(curl -sS "$url" |
                grep -Eom1 "https://download.java.net/openjdk/(open)?jdk$java_version.+linux-x64.tar.gz" ||
                die "Failed to parse download URL")"

timestamp "Downloading $download_url"
wget -c "$download_url"
timestamp "Download complete"
