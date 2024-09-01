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

spark_port=4040

kube_config_isolate

timestamp "Getting Spark pods"
spark_driver_pods="$(
    kubectl get pods ${namespace:+-n "$namespace"} \
                     -l spark-role=driver \
                     --field-selector=status.phase=Running |
    tail -n +2
)"

if [ -z "$spark_driver_pods" ]; then
    die "No Spark driver pods found"
fi

num_lines="$(wc -l <<< "$spark_driver_pods")"

if [ "$num_lines" -eq 1 ]; then
    timestamp "Only one Spark driver pod found"
    spark_driver_pod="$(awk '{print $1}' <<< "$spark_driver_pods")"
elif [ "$num_lines" -gt 1 ]; then
    timestamp "Multiple Spark driver pods found, launching selection menu"
    menu_items=()
    while read -r line; do
        menu_items+=("$line" "")
    done <<< "$spark_driver_pods"
    chosen_pod="$(dialog --menu "Choose which Spark pod to forward to:" "$LINES" "$COLUMNS" "$LINES" "${menu_items[@]}" 3>&1 1>&2 2>&3)"
    if [ -z "$chosen_pod" ]; then
        timestamp "Cancelled, aborting..."
        exit 1
    fi
    spark_driver_pod="$(awk '{print $1}' <<< "$chosen_pod")"
else
    die "ERROR: No Spark driver pods found"
fi

local_port="$spark_port"
while netstat -lnt | grep -q ":$local_port "; do
    timestamp "Local port '$local_port' in use, trying next port"
    ((local_port += 1))
    if [ "$local_port" -gt 65535 ]; then
        die "ERROR: No local port found available"
    fi
done

timestamp "Launching port forwarding to pod '$spark_driver_pod' port '$spark_port' to local port '$local_port'"
kubectl port-forward --address 127.0.0.1 ${namespace:+-n "$namespace"} "$spark_driver_pod" "$local_port":"$spark_port" &
pid=$!
sleep 2
if ! kill -0 "$pid" 2>/dev/null; then
    die "ERROR: kubectl port-forward exited"
fi
echo
url="http://localhost:$local_port"
timestamp "Spark UI is now available at: $url"

if is_mac; then
    echo
    timestamp "Opening URL:  $url"
    open "$url"
fi
