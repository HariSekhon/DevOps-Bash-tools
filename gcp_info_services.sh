#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists GCP services & APIs enabled in the current GCP Project
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

# Services & APIs Enabled
cat <<EOF
# ============================================================================ #
#                 S e r v i c e s   &   A P I s   E n a b l e d
# ============================================================================ #

EOF

if ! type is_service_enabled &>/dev/null; then
    echo "getting list of all services & APIs (will use this to determine which services to list based on what is enabled)" >&2
    . "$srcdir/gcp_service_apis.sh" >/dev/null
    echo >&2
    echo >&2
fi

echo "Services Enabled:"
echo
gcloud services list --enabled
