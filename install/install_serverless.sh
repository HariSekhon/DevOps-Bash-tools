#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-21 10:46:30 +0100 (Wed, 21 Oct 2020)
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
Installs serverless.com binary to ~/.serverless/bin/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

if [ -n "${FORCE_INSTALL:-}" ] || ! type -P serverless &>/dev/null; then
    curl -o- -L https://slss.io/install | bash
else
    echo "serverless is already installed. To upgrade run 'serverless upgrade'"
fi

# configure by first run of:
#
#   serverless
#
# uninstall via:
#
#   serverless uninstall

echo
echo "Serverless Version:"
echo

serverless --version
