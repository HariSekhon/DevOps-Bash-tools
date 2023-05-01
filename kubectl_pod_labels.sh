#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-04-27 15:56:59 +0100 (Tue, 27 Apr 2021)
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
Lists Kubernetes pods and their labels, one per line (more convenient for shell piping)

Specify kubectl options like --namespace '...' or --all-namespaces are arguments like you normally would

Output Format:

<namespace>     <pod_name>     <label_key>=<label_value>
<namespace>     <pod_name>     <label_key2>=<label_value2>
<namespace>     <pod_name2>    <label_key>=<label_value>
...


This format is much easier to read and work with while scripting than multiple labels return on a single line by:

    kubectl get pods --show-labels


Requires kubectl to be installed and configured


If you only want to see a a list of unique available labels:

    ${0##*/} | awk '{print \$2}' | sort -u
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<kubectl_options>]"

help_usage "$@"

kube_config_isolate

kubectl get pods -o json "$@" |
jq -r '
    .items[] |
    {"namespace": .metadata.namespace, "name": .metadata.name, "label": .metadata.labels | to_entries[] } |
    [.namespace, .name, .label.key + "=" + .label.value ] |
    @tsv
' |
column -t
