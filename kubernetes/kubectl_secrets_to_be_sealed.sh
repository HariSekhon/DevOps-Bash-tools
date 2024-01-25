#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-01 15:10:29 +0100 (Mon, 01 Aug 2022)
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

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Returns all secrets that have the annotation sealedsecrets.bitnami.com/managed=\"true\" set, ie. waiting to be replaced by Bitnami Sealed Secrets

Useful to track progress in migrations to Sealed Secrets

See Also:

    kubernetes_secrets_to_sealed_secrets.sh - sets the annotation for the secret to be overwritten

Requires kubectl to be install in the \$PATH and configured with the right context
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<kubectl_options>"

help_usage "$@"

"$srcdir/kubectl_get_annotation.sh" secrets sealedsecrets.bitnami.com/managed '"true"' "$@"
