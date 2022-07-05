#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-05 23:50:40 +0100 (Tue, 05 Jul 2022)
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

# shellcheck disable=SC1090
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Digital Ocean CLI
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#min_args 1 "$@"

#version="${1:-1.78.0}"
version="${1:-latest}"

owner_repo='digitalocean/doctl'

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub API"
    version="$("$srcdir/../github_repo_latest_release.sh" "$owner_repo")"
    version="${version#v}"
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
fi

export RUN_VERSION_ARG=1

"$srcdir/../install_binary.sh" "https://github.com/digitalocean/doctl/releases/download/v$version/doctl-$version-{os}-{arch}.tar.gz" doctl

if [ -n "${DIGITAL_OCEAN_TOKEN:-}" ]; then
    if [ -f "$HOME/Library/Application Support/doctl/config.yaml" ]; then
        if ! grep -Eq 'access-token: .{3,}' "$HOME/Library/Application Support/doctl/config.yaml"; then
            echo
            echo "Setting up authentication"
            echo
            "$srcdir/doctl_auth_init.exp"
        fi
    fi
fi
