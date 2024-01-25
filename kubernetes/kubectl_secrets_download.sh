#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-01 16:49:06 +0100 (Mon, 01 Aug 2022)
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
Downloads all Kubernetes secrets in the current or given namespace to files in the local directory named secret-<name>.yaml

Useful for backing up all your live secrets before migrating to Sealed Secrets or External Secrets
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<kubectl_options>]"

help_usage "$@"

kubectl get secrets --no-headers -o custom-columns=":metadata.name" "$@" |
while read -r secret; do
    filename="secret-$secret.$(date '+%F_%H-%M-%S').yaml"
    timestamp "Downloading secret '$secret' to '$filename'"
    kubectl get secrets "$secret" "$@" -o yaml > "$filename"
done

echo "Done"
