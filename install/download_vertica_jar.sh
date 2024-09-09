#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-27 14:12:50 +0200 (Tue, 27 Aug 2024)
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
Quickly determines and downloads latest Vertica JDBC jar or an explicitly given version

Useful to get the jar to upload to data integration 3rd party directories or Docker images or Kubernetes
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

#version="24.2.0"
version="${1:-latest}"

downloads_url="https://www.vertica.com/download/vertica/client-drivers/"

# ERE format for grep -E
jar_url_regex="https://www.vertica.com/client_drivers/[[:digit:].x-]+/[[:digit:].-]+/vertica-jdbc-[[:digit:].-]+.jar"

# Should match these:
#
# https://www.vertica.com/client_drivers/24.2.x/24.2.0-1/vertica-jdbc-24.2.0-1.jar
# https://www.vertica.com/client_drivers/24.1.x/24.1.0-0/vertica-jdbc-24.1.0-0.jar
# https://www.vertica.com/client_drivers/23.4.x/23.4.0-0/vertica-jdbc-23.4.0-0.jar
# https://www.vertica.com/client_drivers/23.3.x/23.3.0-0/vertica-jdbc-23.3.0-0.jar
# https://www.vertica.com/client_drivers/12.0.x/12.0.4-0/vertica-jdbc-12.0.4-0.jar
# https://www.vertica.com/client_drivers/11.1.x/11.1.1-0/vertica-jdbc-11.1.1-0.jar
# https://www.vertica.com/client_drivers/11.0.x/11.0.2-0/vertica-jdbc-11.0.2-0.jar
# https://www.vertica.com/client_drivers/10.1.x/10.1.1-0/vertica-jdbc-10.1.1-0.jar
# https://www.vertica.com/client_drivers/10.0.x/10.0.1-0/vertica-jdbc-10.0.1-0.jar
# https://www.vertica.com/client_drivers/9.3.x/9.3.1-0/vertica-jdbc-9.3.1-0.jar
# https://www.vertica.com/client_drivers/9.2.x/9.2.1-0/vertica-jdbc-9.2.1-0.jar
# https://www.vertica.com/client_drivers/9.2.x/9.2.1-0/vertica-jdbc-9.2.1-0.jar
# https://www.vertica.com/client_drivers/9.1.x/9.1.1-0/vertica-jdbc-9.1.1-0.jar
# https://www.vertica.com/client_drivers/9.0.x/9.0.1-0/vertica-jdbc-9.0.1-0.jar
# https://www.vertica.com/client_drivers/8.1.x/8.1.1-0/vertica-jdbc-8.1.1-0.jar
# https://www.vertica.com/client_drivers/8.0.x/8.0.1/vertica-jdbc-8.0.1-0.jar
# https://www.vertica.com/client_drivers/7.2.x/7.2.3-0/vertica-jdbc-7.2.3-0.jar

timestamp "Fetching list of Vertica JDBC JAR download URLs from $downloads_url"
jar_urls="$(
    curl -sS "$downloads_url" |
    grep -Eo "$jar_url_regex"
)"

if [ "$version" = "latest" ]; then
    timestamp "Determining latest version from list of JAR download urls"
    download_url="$(head -n1 <<< "$jar_urls")"
    timestamp "Determined latest JAR version to be ${download_url##*/}"
else
    timestamp "Checking if requested version '$version' is available"
    download_url="$(grep "$version" <<< "$jar_urls" | head -n 1 || :)"
    if [ -z "$download_url" ]; then
        echo
        echo "ERROR: Vertica JDBC JAR version '$version' not found" >&2
        echo
        echo "Here are the list of available versions:"
        echo
        sed 's/.*vertica-jdbc-//; s/-[[:digit:]]\+.jar$//' <<< "$jar_urls"
        echo
        exit 1
    fi
fi

"$srcdir/../bin/download_url_file.sh" "$download_url"
