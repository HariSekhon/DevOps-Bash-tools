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
Dumps Kubernetes Java JStacks to text files for every pod that matches a given regex in the given namespace

Useful for debugging Spark jobs on Kubernetes


Dumps command outputs to files of this name format:

kubectl-pod-jstack.YYYY-MM-DD-HHSS.POD_NAME.txt


Requires kubectl to be installed and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<jdk_dir> [<namespace> <pod_name_regex>]"

help_usage "$@"

min_args 1 "$@"
max_args 3 "$@"

jdk="$1"
namespace="${2:-}"
regex="${3:-.}"

kube_config_isolate

if [ -n "$namespace" ]; then
    echo "Switching to namespace '$namespace'";
    kubectl config set-context "$(kubectl config current-context)" --namespace "$namespace"
    echo
fi

kubectl get pods -o name |
sed 's|pod/||' |
grep -E "$regex" |
while read -r pod; do
    echo
    timestamp "Dumping pod jstack: $pod"
    output_file="kubectl-pod-jstack.$(date '+%F_%H%M').$pod.txt"
    #kubectl exec"$pod" -- "rm -fr /tmp/jdk"
    timestamp "Copying jdk '$jdk' to pod /tmp"
    kubectl cp "$jdk/" "$pod":/tmp/jdk
    timestamp "Dumping JStack inside pod"
    # want expansion in pod not local shell
    # shellcheck disable=SC2016
    kubectl exec "$pod" -- \
        bash -c '
            java_pid="$(pgrep java | tee /dev/stderr)"
            java_pids=($java_pid)
            if [ "${#java_pids[@]}" -gt 1 ]; then
                  echo "WARNING: more than one Java PID returned: ${java_pids[*]}"
            elif [ "${#java_pids[@]}" -eq 0 ]; then
                echo "WARNING: no Java PID found (perhaps you need to regex filter to only pods running Java processes?" |
                tee /tmp/jstack-output.txt /dev/stderr
                exit 0
            fi
            /tmp/jdk/bin/jstack "$java_pid" > /tmp/jstack-output.txt
        '
    kubectl cp "$pod":/tmp/jstack-output.txt "$output_file"
    timestamp "Dumped pod jstack to file: $output_file"
done
