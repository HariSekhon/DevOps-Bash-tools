#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-01-11 10:07:36 +0000 (Tue, 11 Jan 2022)
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
Installs NGrok CLI

If \$NGROK_AUTHTOKEN or \$NGROK_TOKEN is set, configures authentication using that token, in that order of precedence

https://dashboard.ngrok.com/get-started/your-authtoken
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<version>]"

export PATH="$PATH:$HOME/bin"

help_usage "$@"

#min_args 1 "$@"

version="${1:-v3-stable}"

export RUN_VERSION_ARG=1

# XXX: passing 'v2-stable' as version the URL gets updated but it still downloads v3, not sure how to predict this :-/
"$srcdir/../packages/install_binary.sh" "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-$version-{os}-{arch}.zip" "ngrok"

TOKEN="${NGROK_AUTHTOKEN:-${NGROK_TOKEN:-}}"

if [ -n "${TOKEN:-}" ]; then
    echo
    timestamp "found, \$NGROK_TOKEN, configuring authentication"
    ngrok config add-authtoken "$TOKEN"
    timestamp "authentication configured"
fi
