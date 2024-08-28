#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-28 20:57:31 +0200 (Wed, 28 Aug 2024)
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
Quickly determines and downloads latest CFR java command line decompiler jar or an explicitly given version

Version defaults to 'latest' in which case it determines the latest version from GitHub releases
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

version="${1:-latest}"

github_owner_repo="leibnitz27/cfr"

if [ "$version" = latest ]; then
    timestamp "Determining latest version of CFR available"
    version="$(github_repo_latest_release.sh "$github_owner_repo")"
    version="${version#v}"
    timestamp "Determined latest version of CFR to be version '$version'"
fi

# avoid race condition between different sites updating at different times and pull from GitHub releases where we determined latest version to be from
#download_url="https://jdbc.postgresql.org/download/postgresql-$version.jar"
download_url="https://github.com/$github_owner_repo/releases/download/$version/cfr-$version.jar"

timestamp "Downloading Java Decompiler CFR version '$version' from: $download_url"
echo >&2

jar="cfr-$version.jar"

if type -P wget &>/dev/null; then
    wget -cO "$jar" "$download_url"
else
    tmpfile="$(mktemp)"
    curl --fail "$download_url" > "$tmpfile"
    unalias mv &>/dev/null || :
    mv -fv "$tmpfile" "$jar"
fi

timestamp "Download complete: $jar"
