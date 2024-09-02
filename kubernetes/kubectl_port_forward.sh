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
Launches kubectl port-forward to a pod

Optional second argument may specify a grep ERE regex on the pod line or
a more specific key=value kubernetes label (the latter is preferable)

If more than one matching pod is found, prompts with an interactive dialogue to choose one

If more than one pod port is found, you will be prompted with another interactive dialog
unless you can define the environment variable POD_PORT instead

If OPEN_URL environment variable is set and this script is not run over SSH then automatically
opens the UI on localhost URL in the default browser
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace> <pod_line_ERE_regex_or_key=value_label>]"

help_usage "$@"

max_args 2 "$@"

namespace="${1:-}"
filter="${2:-}"
#filter_label=()
filter_label=""
grep_filter=""

if [[ "$filter" =~ = ]]; then
    #filter_label=(-l "$filter")
    #
    # this works on Bash 3 set -u but breaks on Bash 4
    #
    #   "${filter_label[@]}"
    #
    # the fix on Bash 4 is
    #
    #   "${filter_label[@:-]}"
    #
    # but that isn't recognized on Bash 3
    #
    # portable workaround, convert to string and don't quote
    #
    filter_label="-l $filter"
elif [ -n "$filter" ]; then
    grep_filter="$filter"
fi

kube_config_isolate

timestamp "Getting pods that match filter '$filter'"
# need splitting due to above behavioural difference between Bash 3 and Bash 4
# shellcheck disable=SC2086
pods="$(
    kubectl get pods ${namespace:+-n "$namespace"} \
                     $filter_label \
                     --field-selector=status.phase=Running |
    if [ -n "$grep_filter" ]; then
        grep -E "$grep_filter"
    else
        cat
    fi |
    tail -n +2
)"

if [ -z "$pods" ]; then
    die "No matching pods found"
fi

num_lines="$(wc -l <<< "$pods")"

if [ "$num_lines" -eq 1 ]; then
    timestamp "Only one matching Kubernetes pod found"
    pod="$(awk '{print $1}' <<< "$pods")"
elif [ "$num_lines" -gt 1 ]; then
    timestamp "Multiple Kubernetes pods found, launching selection menu"
    menu_items=()
    while read -r line; do
        menu_items+=("$line" "")
    done <<< "$pods"
    if [ "${#menu_items[@]}" -eq 0 ]; then
        die "Pod menu generation failed: empty"
    fi
    chosen_pod="$(dialog --menu "Choose which Kubernetes pod to forward to:" "$LINES" "$COLUMNS" "$LINES" "${menu_items[@]}" 3>&1 1>&2 2>&3)"
    if [ -z "$chosen_pod" ]; then
        timestamp "Cancelled, aborting..."
        exit 1
    fi
    pod="$(awk '{print $1}' <<< "$chosen_pod")"
else
    die "ERROR: No matching pods found"
fi

if [ -n "${POD_PORT:-}" ]; then
    if ! is_port "$POD_PORT"; then
        die "Environment variable POD_PORT must be a valid port number integer"
    fi
    pod_port="$POD_PORT"
else
    pod_port="$(kubectl get pod  ${namespace:+-n "$namespace"} "$pod" -o jsonpath='{.spec.containers[*].ports[*].containerPort}')"
fi

if [ -z "$pod_port" ]; then
    die "Failed to determine port for pod '$pod'"
fi

if [ "$(awk '{print NF}' <<< "$pod_port")" -gt 1 ]; then
    timestamp "More than one port found on the pod, prompting for selection"
    menu_items=()
    while read -r line; do
        menu_items+=("$line" "")
    done < <(tr ' ' '\n' <<< "$pod_port" | sed '/^[[:space:]]*$/d')
    if [ "${#menu_items[@]}" -eq 0 ]; then
        die "Port menu generation failed: empty"
    fi
    chosen_port="$(dialog --menu "Choose which port to forward to:" "$LINES" "$COLUMNS" "$LINES" "${menu_items[@]}" 3>&1 1>&2 2>&3)"
    if [ -z "$chosen_port" ]; then
        timestamp "Cancelled, aborting..."
        exit 1
    fi
    pod_port="$chosen_port"
fi

local_port="$pod_port"

if [ "$local_port" -lt 1024 ]; then
    if [ "$local_port" = 80 ]; then
        local_port=8080
    elif [ "$local_port" = 443 ]; then
        local_port=8443
    else
        local_port="$((local_port + 1000))"
    fi
fi
local_port="$(next_available_port "$pod_port")"

timestamp "Launching port forwarding to pod '$pod' port '$pod_port' to local port '$local_port'"
kubectl port-forward --address 127.0.0.1 ${namespace:+-n "$namespace"} "$pod" "$local_port":"$pod_port" &

pid="$!"

sleep 2

if ! kill -0 "$pid" 2>/dev/null; then
    die "ERROR: kubectl port-forward exited"
fi

if [ -z "${SSH_CONNECTION:-}" ]; then
    echo
    url="http://localhost:$local_port"
    timestamp "Port-forwarded UI is now available at: $url"

    if [ -n "${OPEN_URL:-}" ]; then
        echo
        timestamp "Opening URL:  $url"
        "$srcdir/../bin/urlopen.sh" "$url"
    fi
fi
