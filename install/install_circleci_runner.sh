#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-12-13 18:23:41 +0000 (Mon, 13 Dec 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://circleci.com/docs/2.0/runner-installation/#installation

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Downloads the CircleCI Runner launch agent to ~/bin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"  # linux or darwin
arch="$(uname -m)"  # x86_64 or amd64
if [ "$arch" = x86_64 ]; then
    arch="amd64"
fi
platform="$os/$arch"

base_url="https://circleci-binary-releases.s3.amazonaws.com/circleci-launch-agent"
agent_version=$(curl -sS --fail "${base_url}/release.txt")

timestamp "Using CircleCI Launch Agent version $agent_version"
echo >&2

prefix=~/bin/circleci-runner

mkdir -p "$prefix/workdir"

tmp="$(mktemp -d)"

cd "$tmp"

timestamp "Downloading and verifying CircleCI Launch Agent Binary"
curl -sSL --fail "$base_url/$agent_version/checksums.txt" -o checksums.txt
file="$(grep -F "$platform" checksums.txt | cut -d ' ' -f 2 | sed 's/^.//')"
echo >&2

mkdir -p "$platform"

timestamp "Downloading CircleCI Launch Agent: $file"
curl -sS --fail --compressed -L "$base_url/$agent_version/$file" -o "$file"
echo >&2

timestamp "Verifying CircleCI Launch Agent download"
grep "$file" checksums.txt |
sha256sum --check

chmod +x "$file"

cp -v -- "$file" "$prefix/circleci-launch-agent"
