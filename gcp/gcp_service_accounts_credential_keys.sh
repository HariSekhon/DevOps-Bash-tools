#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-10-28 14:02:13 +0000 (Wed, 28 Oct 2020)
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
List all service account credential keys in the current GCP project along with their creation and expiry dates

Excludes built-in system managed keys which are hidden in the Console UI anyway and are not actionable
or in scope for a key policy audit.

To get a list of all user managed keys with no expiry set, you can simply grep the output from this script:

    ${0##*/} | grep 9999-12-31T23:59:59Z


Output Format:

<key_id>  <created_date>  <expiry_date>  <service_account_email>


Requires GCloud SDK to be installed and configured for your project


See Also:

    gcp_service_account_credential_keys.py

in the DevOps Python tools repo:

    https://github.com/HariSekhon/DevOps-Python-tools/
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

service_accounts="$(gcloud iam service-accounts list --format='get(email)')"

for service_account in $service_accounts; do
    gcloud iam service-accounts keys list --iam-account "$service_account" \
                                          --format='table[no-heading](name.basename(), validAfterTime, validBeforeTime)' \
                                          --filter='keyType != SYSTEM_MANAGED' |
    # suffixing is better for alignment as service account email lengths are the only variable field and otherwise
    # this comes out all misaligned or we have to pipe through column -t with no progress output,
    # leaving appearance of a long O(n) hang before results
    #sed "s/^/$service_account    /"
    sed "s/$/  $service_account/"
done
