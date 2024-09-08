#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-01-03 19:13:35 +0000 (Sun, 03 Jan 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Downloads Golang to ~/bin

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Golang to ~/bin

Uses GitHub CLI (installs it if not already installed
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

max_args 1 "$@"

#version="${1:-1.15.6}"
version="${1:-latest}"

owner_repo="golang/go"

install_location=~/bin

uname_s="$(uname -s | tr '[:upper:]' '[:lower:]')"

tmp_tar="$(mktemp)"

if [ "$version" = latest ]; then
    timestamp "determining latest version of '$owner_repo' via GitHub CLI API"
    # Golang has no GitHub releases but all tags
    #version="$("$srcdir/github_repo_latest_release.sh" "$owner_repo")"
    type -P gh &>/dev/null || "$srcdir/install_github_cli.sh"
    version="$(gh api "repos/$owner_repo/tags" \
                --jq '
                    .[] |
                    select(.name | test("^go[0-9]")) |
                    .name
                ' --paginate |
                head -n1 |
                sed 's/^go//' || :)"
    if [ -z "$version" ]; then
        die "Failed to determine latest version of $owner_repo"
    fi
    timestamp "latest version is '$version'"
else
    is_semver "$version" || die "non-semver version argument given: '$version' - should be in format: N.N.N"
fi

url="https://golang.org/dl/go$version.$uname_s-amd64.tar.gz"

mkdir -p -v "$install_location"

echo "$(date '+%F %T')  Downloading $url"
wget -cO "$tmp_tar" "$url"

echo "$(date '+%F %T')  Unpacking to $install_location"
tar zxf "$tmp_tar" -C "$install_location"

echo
echo "Golang installed to $install_location"
echo
echo "To make use of it set the following:"
echo
echo "export PATH=\"$install_location/go/bin:\$PATH\""
echo "export GOROOT=\"$install_location/go\""
