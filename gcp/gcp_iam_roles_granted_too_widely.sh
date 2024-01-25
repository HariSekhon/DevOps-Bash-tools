#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-19 12:26:49 +0000 (Fri, 19 Feb 2021)
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
Finds roles granted too widely in the current / given GCP project, or search across all your projects

Uses the adjacent script gcp_iam_roles_granted_to_identity.sh to search for the special GCP groups allAuthenticatedUsers and allUsers which should usually not be granted to anything

See gcp_iam_roles_granted_to_identity.sh for more details
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

project=("${1:-}")

echo "Roles granted to all authenticated users:"
"$srcdir/gcp_iam_roles_granted_to_identity.sh" group:allAuthenticatedUsers "${project[@]}"
echo
echo "Roles granted to even unauthenticated users:"
"$srcdir/gcp_iam_roles_granted_to_identity.sh" group:allUsers "${project[@]}"
echo
