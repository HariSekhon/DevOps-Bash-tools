#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-27 14:21:49 +0000 (Fri, 27 Nov 2020)
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
Quickly determines and downloads latest PostgreSQL JDBC jar or an explicitly given version

Useful to get the jar to upload to data integration 3rd party directories or Docker images or Kubernetes
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

#version="${1:-42.2.18}"
version="${1:-latest}"

github_owner_repo="pgjdbc/pgjdbc"

if [ "$version" = latest ]; then
    timestamp "Determining latest version of PostgreSQL JDBC driver available"
    version="$(github_repo_latest_release.sh "$github_owner_repo")"
    version="${version#REL}"
    timestamp "Determined latest version of PostgreSQL JDBC driver to be version '$version'"
fi

# avoid race condition between different sites updating at different times and pull from GitHub releases where we determined latest version to be from
#download_url="https://jdbc.postgresql.org/download/postgresql-$version.jar"
download_url="https://github.com/pgjdbc/pgjdbc/releases/download/REL$version/postgresql-$version.jar"

timestamp "Downloading PostgreSQL JDBC version '$version' from $download_url"
echo >&2

jar="postgresql-jdbc-$version.jar"

if type -P wget; then
    wget -cO "$jar" "$download_url"
else
    tmpfile="$(mktemp)"
    curl --fail "$download_url" > "$tmpfile"
    unalias mv &>/dev/null || :
    mv -fv "$tmpfile" "$jar"
fi

timestamp "Download complete"
