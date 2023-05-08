#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-05 14:48:56 +0000 (Fri, 05 Feb 2021)
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
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists all risky GCP Firewall rules enabled in the current project that are open with source range 0.0.0.0/0 (whole internet can pass through)

Such rules should be rare, eg:

- your public website (and even then only if not using full Cloudflare Proxied protection)

- GKE ingress generated GCP firewall rules (too open by default)
    - to lock them down see my adjacent Kubernetes-templates repo's service.yaml:

    https://github.com/HariSekhon/Kubernetes-templates/blob/master/service.yaml
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<project_id>"

help_usage "$@"

max_args 1 "$@"

opts=()
if [ -n "${1:-}" ]; then
    opts+=(--project "$1")
fi

gcloud compute firewall-rules list --format='table[no-heading](name,source_ranges)' --filter='disabled=false' "${opts[@]}" |
{ grep "'0.0.0.0/0'" || : ; }
