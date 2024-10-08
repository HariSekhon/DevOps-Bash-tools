#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-10-08 05:24:37 +0300 (Tue, 08 Oct 2024)
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
Runs Prometheus locally

Installs it to \$PATH if not already available
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<prometheus_args>]"

help_usage "$@"

if ! type -P prometheus &>/dev/null; then
    "$srcdir/../install/install_prometheus.sh"
fi

prometheus "$@"
