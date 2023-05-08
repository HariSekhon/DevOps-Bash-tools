#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-04-28 23:37:29 +0100 (Wed, 28 Apr 2021)
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
Lists GCP Secrets labels in tabular form suitable for quick reviews and shell pipelines

Does not list secrets without labels as this is primarily a label review tool


Output Format:

<secret1_name>   <label_key1>=<label_value1>
<secret1_name>   <label_key2>=<label_value2>
<secret2_name>   <label_key1>=<label_value1>
...


Requires GCloud SDK to be installed and configured


See Also:

    gcp_secrets_update_label.sh - updates all matching labels of a given value with a new value (eg. when migrating Kubernetetes namespaces)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

gcloud secrets list --format=json  |
jq -r '
    .[] |
    select(.labels) |
    {"name": .name, "label": (.labels | to_entries[]) } |
    [.name, .label.key + "=" + .label.value] |
    @tsv' |
column -t
