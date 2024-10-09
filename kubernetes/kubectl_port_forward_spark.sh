#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-09-01 14:06:16 +0200 (Sun, 01 Sep 2024)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Launches kubectl port-forward to Spark driver pod for Spark UI

If more than one Spark driver pod is found, prompts with an interactive dialogue to choose one

On Mac automatically opens the Spark UI on localhost URL in the default browser
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace>]"

help_usage "$@"

max_args 1 "$@"

namespace="${1:-}"

export OPEN_URL=1

export POD_PORT=4040

"$srcdir/kubectl_port_forward.sh" "$namespace" spark-role=driver
