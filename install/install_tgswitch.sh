#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-01-08 12:54:27 +0700 (Wed, 08 Jan 2025)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Installs tgswitch for managing Terragrunt versions
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

help_usage "$@"

max_args 1 "$@"

#version="${1:-2.4.0}"
version="${1:-latest}"

export HOME="${HOME:-$(cd && pwd)}"

export PATH="$HOME/bin:$PATH"

#if is_mac; then
#    brew install warrensbox/tap/tgswitch
#else
    # Tries to install to /usr/local/bin/ and gets permission denied
    #curl -L https://raw.githubusercontent.com/warrensbox/tgswitch/release/install.sh | bash
    "$srcdir/../github/github_install_binary.sh" warrensbox/tgswitch "tgswitch_{version}_{os}_{arch}.tar.gz" "$version" "tgswitch"
#fi

echo
echo -n "Terragrunt "
tgswitch --version
