#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-04-16 01:46:54 +0100 (Sun, 16 Apr 2023)
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
Installs Knative CLI on Mac using Brew for kn and func

Then determines the latest func version from GitHub and downloads the release binary to 'kn-func' to use as a kn plugin
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<func_version>] [<options>]"

help_usage "$@"

#min_args 1 "$@"

version="${1:-latest}"

timestamp "Installing knative/client/kn"
brew install knative/client/kn
echo

timestamp "Installing knative-sandbox/kn-plugins/quickstart"
brew install knative-sandbox/kn-plugins/quickstart
echo

timestamp "Open brew tap knative-sandbox/kn-plugins"
brew tap knative-sandbox/kn-plugins
echo

timestamp "Installing func"
brew install func
echo

timestamp "Downloading func latest release as fn plugin"

"$srcdir/../github_install_binary.sh" knative/func "func_{os}_{arch}" "$version" kn-func

echo -n "Knative func plugin version: "
kn func version
