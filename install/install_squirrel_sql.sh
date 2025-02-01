#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-13 15:40:23 +0300 (Sun, 13 Oct 2024)
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

config="$srcdir/../setup/squirrelsql-install-options.xml"
config="$(readlink -f "$config")"

# shellcheck disable=SC2034,SC2154
usage_description="
Install SQuirreL SQL Client

Allows you to install with a custom config:

    $config
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

max_args 1 "$@"

version="${1:-latest}"

owner_repo="squirrel-sql-client/squirrel-sql-stable-releases"

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github/github_repo_latest_release.sh" "$owner_repo")"
    version="${version%%-*}"
    timestamp "latest version is '$version'"
fi
is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"

export RUN_VERSION_ARG=1

if is_mac; then
    os="MACOSX"
else
    os="standard"
fi

cd /tmp

download_url="https://github.com/squirrel-sql-client/squirrel-sql-stable-releases/releases/download/$version-installer/squirrel-sql-$version-$os-install.jar"

"$srcdir/../bin/download_url_file.sh" "$download_url"

install_jar="${download_url##*/}"

java -jar "./$install_jar" -options-system "$config"  # file with settings or where to install from the homebrew

if is_mac; then
    timestamp "Launching SQuirreL"
    #open -a SQuirreLSQL
    # this is where is installs to
    open -a /Applications/SQuirreLSQL.app
fi
