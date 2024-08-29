#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-22 11:58:37 +0200 (Thu, 22 Aug 2024)
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
Dumps common Linux command outputs for every pod that matches a given regex in the given namespace

Useful for debugging Spark jobs on Kubernetes


Dumps command outputs to files of this name format:

kubectl-pod-dump-output.YYYY-MM-DD-HHSS.POD_NAME.txt


Requires kubectl to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace> <pod_name_regex>]"

help_usage "$@"

max_args 2 "$@"

namespace="${1:-}"
pod_name_regex="${2:-.}"

kube_config_isolate

if [ -n "$namespace" ]; then
    echo "Switching to namespace '$namespace'";
    kubectl config set-context "$(kubectl config current-context)" --namespace "$namespace"
    echo
fi

kubectl get pods -o name |
sed 's|pod/||' |
grep -E "$pod_name_regex" |
while read -r pod; do
    echo
    # ignore && && || it works
    # shellcheck disable=SC2015
    timestamp "Running stats commands on pod: $pod" &&
    output_file="kubectl-pod-stats.$(date '+%F_%H%M').$pod.txt" &&
    echo &&
    # Copied from ../bin/dump_stats.sh for servers
    #
    # Most of these won't be available inside a pod, but we can only try...
    kubectl exec "$pod" -- bash -c '
        # sent errors to stdout to be captured in the log sections of why the stats are not available eg.
        #
        #   bash: line 25: iostat: command not found
        #   bash: line 35: mpstat: command not found
        #   bash: line 39: sar: command not found
        #   bash: line 44: sar: command not found
        #   bash: line 68: netstat: command not found
        #   bash: line 73: lsof: command not found
        #
        exec 2>&1

        echo "Dumping common command outputs"
        echo
        echo "Disk Space:"
        echo
        df -h
        echo
        echo
        echo "Uname:"
        echo
        uname -a
        echo
        echo
        echo "Uptime:"
        echo
        uptime
        echo
        echo
        echo "RAM in GB:"
        echo
        free -g
        echo
        echo
        echo "IOstat:"
        echo
        iostat -x 1 5
        echo
        echo
        echo "lsblk:"
        echo
        lsblk
        echo
        echo
        echo "MPstat:"
        echo
        mpstat -P ALL 1 5
        echo
        echo
        echo "SAR 1 sec intervals x 5:"
        sar -u 1 5
        echo
        echo
        echo "SAR -A:"
        echo
        sar -A
        echo
        echo
        echo "Top snapshot with Threads:"
        top -H -b -n 1
        echo
        echo
        echo "VMstat:"
        echo
        vmstat 1 5
        echo
        echo
        echo "Process List:"
        echo
        ps -ef
        echo
        echo
        echo "ps auxf:"
        echo
        ps auxf
        echo
        echo
        echo "Netstat:"
        echo
        netstat -an
        echo
        echo
        echo "LSOF:"
        echo
        lsof -n -O
        echo
        echo
        echo "Dmesg:"
        echo
        dmesg
    ' >"$output_file" &&
    echo &&
    timestamp "Dumped stats commands outputs to file: $output_file" &&
    echo &&
    echo ||
    warn "Failed to collect stats for pod '$pod'"
    # XXX: because race condition - pods can go away during execution and we still want to collect the rest of the pods
done
timestamp "Stats dumps completed"
