#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-16 13:47:47 +0200 (Mon, 16 Sep 2024)
#  (ported from Knowledge Base avro page)
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
Quickly determines and downloads latest Apache Avro Tools jar or an explicitly given version
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

#version="1.12.0"
version="${1:-latest}"

downloads_url='https://repo1.maven.org/maven2/org/apache/avro/avro-tools'

# ERE format for grep -E
version_regex='<a href="[[:digit:]]+.[[:digit:]]+.[[:digit:]]+/" title="[[:digit:]]+.[[:digit:]]+.[[:digit:]]+/">([[:digit:]]+.[[:digit:]]+.[[:digit:]]+)/</a>'

# Should match these:
#
# <a href="1.10.0/" title="1.10.0/">1.10.0/</a>
# <a href="1.10.1/" title="1.10.1/">1.10.1/</a>
# <a href="1.10.2/" title="1.10.2/">1.10.2/</a>
# <a href="1.11.0/" title="1.11.0/">1.11.0/</a>
# <a href="1.11.1/" title="1.11.1/">1.11.1/</a>
# <a href="1.11.2/" title="1.11.2/">1.11.2/</a>
# <a href="1.11.3/" title="1.11.3/">1.11.3/</a>
# <a href="1.12.0/" title="1.12.0/">1.12.0/</a>
# <a href="1.5.0/" title="1.5.0/">1.5.0/</a>
# <a href="1.5.1/" title="1.5.1/">1.5.1/</a>
# <a href="1.5.2/" title="1.5.2/">1.5.2/</a>
# <a href="1.5.3/" title="1.5.3/">1.5.3/</a>
# <a href="1.5.4/" title="1.5.4/">1.5.4/</a>
# <a href="1.6.0/" title="1.6.0/">1.6.0/</a>
# <a href="1.6.1/" title="1.6.1/">1.6.1/</a>
# <a href="1.6.2/" title="1.6.2/">1.6.2/</a>
# <a href="1.6.3/" title="1.6.3/">1.6.3/</a>
# <a href="1.7.0/" title="1.7.0/">1.7.0/</a>
# <a href="1.7.1/" title="1.7.1/">1.7.1/</a>
# <a href="1.7.2/" title="1.7.2/">1.7.2/</a>
# <a href="1.7.3/" title="1.7.3/">1.7.3/</a>
# <a href="1.7.4/" title="1.7.4/">1.7.4/</a>
# <a href="1.7.5/" title="1.7.5/">1.7.5/</a>
# <a href="1.7.6/" title="1.7.6/">1.7.6/</a>
# <a href="1.7.7/" title="1.7.7/">1.7.7/</a>
# <a href="1.8.0/" title="1.8.0/">1.8.0/</a>
# <a href="1.8.1/" title="1.8.1/">1.8.1/</a>
# <a href="1.8.2/" title="1.8.2/">1.8.2/</a>
# <a href="1.9.0/" title="1.9.0/">1.9.0/</a>
# <a href="1.9.1/" title="1.9.1/">1.9.1/</a>
# <a href="1.9.2/" title="1.9.2/">1.9.2/</a>


if [ "$version" = "latest" ]; then
    timestamp "Determining latest Avro Tools version from $downloads_url"
    versions="$(
        curl -sS "$downloads_url/" |
        grep -Eo "$version_regex" |
        sed 's|</a>[[:space:]]*$||; s|^.*>||; s|/$||'
    )"
    version="$(sort -Vr <<< "$versions" | head -n 1)"
    timestamp "Determined latest Avro Tools version to be $version"
fi

download_url="$downloads_url/$version/avro-tools-$version.jar"

"$srcdir/../bin/download_url_file.sh" "$download_url"
