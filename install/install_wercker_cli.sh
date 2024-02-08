#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-01 21:01:50 +0000 (Sun, 01 Mar 2020)
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
Installs Wercker CLI
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

export PATH="$PATH:$HOME/bin"

help_usage "$@"

export RUN_VERSION_ARG=1

"$srcdir/../packages/install_binary.sh" "https://s3.amazonaws.com/downloads.wercker.com/cli/stable/{os}_{arch}/wercker"
