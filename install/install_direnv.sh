#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-10 13:09:20 +0300 (Sat, 10 Aug 2024)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Install Direnv using the online install

The online install will install direnv to your local user writable \$PATH
even if there is a direnv already in the \$PATH

This standardized install_<name>.sh script will check for direnv in \$PATH and skip the install if found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

no_args "$@"

if type -P direnv &>/dev/null; then
    echo "direnv is already installed at '$(type -P direnv)', skipping install"
    exit 0
fi

# clean PATH because the direnv installer will write the 'direnv' binary to the first available user writeable path
# and we don't want it putting it somewhere like ~/github/bash-tools - mixed in with git repo and scripts
PATH="$HOME/bin:$(tr ':' '\n' <<< "$PATH" | grep -e '^/bin' -e '^/usr' | tr '\n' ':' | sed 's/:$//')"
export PATH

# ensure we have at least one user writable directory
mkdir -p -v ~/bin

curl -sfL https://direnv.net/install.sh | bash
echo
version="$(direnv version)"
echo "Direnv version: $version"
