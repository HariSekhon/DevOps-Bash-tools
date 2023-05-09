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

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Installs Digital Ocean CLI

If you're on Mac and you have \$DIGITAL_OCEAN_TOKEN set in your environment, will configure it for the default context automatically if no access tokens are configured in your 'Library/Application Support/doctl/config.yaml'
If you have a token \$DIGITALOCEAN_ACCESS_TOKEN this won't be needed because doctl will pick it up automatically so you don't need to configure the config.yml

Generate a personal access token here:

    https://cloud.digitalocean.com/account/api/tokens

CLI Command Reference:

    https://docs.digitalocean.com/reference/doctl/reference/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#version="${1:-1.78.0}"
version="${1:-latest}"

export RUN_VERSION_ARG=1

"$srcdir/../github/github_install_binary.sh" digitalocean/doctl 'doctl-{version}-{os}-{arch}.tar.gz' "$version" doctl

DIGITAL_OCEAN_TOKEN="${DIGITAL_OCEAN_TOKEN:-${DIGITALOCEAN_TOKEN:-}}"

if [ -n "${DIGITAL_OCEAN_TOKEN:-}" ] &&
    # if $DIGITALOCEAN_ACCESS_TOKEN is there the output will change ti 'Validating token... OK' and expect script will break
   [ -z "${DIGITALOCEAN_ACCESS_TOKEN:-}" ]; then
    if is_mac; then
        if ! grep -Eq 'access-token: .{3,}' "$HOME/Library/Application Support/doctl/config.yaml"; then
            echo
            echo "Setting up authentication"
            echo
            "$srcdir/doctl_auth_init.exp"
        fi
    fi
fi
