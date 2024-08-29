#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: https://github.com/pgjdbc/pgjdbc/releases/download/REL{version}/postgresql-{version}.jar latest
#
#  Author: Hari Sekhon
#  Date: 2024-08-28 23:01:46 +0200 (Wed, 28 Aug 2024)
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
. "$srcdir/../lib/github.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Quickly determines and downloads the given or latest version of a GitHub release file

If the file url template contains {version} placeholders but no explicit version then the placeholds will be replaced with the latest version which will be automatically determined from GitHub releases

If the file URL does not contain {version} placeholders then downloads the URL as given

Version defaults to 'latest' in which case it determines the latest version from GitHub releases

Designed to be called from download_github_jar.sh and similar adjacent scripts to deduplicate code
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<url> [<version>]"

help_usage "$@"

check_bin file

min_args 1 "$@"
max_args 2 "$@"

url="$1"
version="${2:-latest}"

if ! [[ "$url" =~ \.jar$ ]]; then
    die "ERROR: given URL is not for a JAR file: $url"
fi

"$srcdir/github_download_release_file.sh" "$url" "$version"
echo >&2

timestamp "Validating JAR content format"
filename="${url##*/}"
filename="${filename//\{version\}/*}"
# have to risk splitting to get globbing to work on latest file
# shellcheck disable=SC2086,SC2046
output="$(file --brief $(ls -tr $filename))"
expected_format="^Zip archive data|^Java archive data \(JAR\)"
if ! [[ "$output" =~ $expected_format ]]; then
    die "ERROR: JAR failed 'file' type matching, expected '$expected_format', got: '$output'"
fi
timestamp "JAR file format validation passed"
