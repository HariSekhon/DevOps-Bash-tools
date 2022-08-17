#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-17 16:45:49 +0100 (Wed, 17 Aug 2022)
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
Install Octopus Deploy CLI
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

version="${1:-9.0.0}"

os="$(get_os)"
if [ "$os" = darwin ]; then
    os=osx
fi

arch="$(get_arch)"
if [ "$arch" = amd64 ]; then
    arch=x64
fi

"$srcdir/../install_binary.sh" "https://download.octopusdeploy.com/octopus-tools/$version/OctopusTools.$version.$os-$arch.tar.gz" octo
