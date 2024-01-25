#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-06-18 11:28:40 +0100 (Fri, 18 Jun 2021)
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
Filter program to get all unique Kubernetes resources types out of a Kubernetes yaml or Kustomize build output

Yaml can be supplied as a file argument or via standard input. If no file is given, waits for stdin like a standard unix filter program

Useful to find objects to grant an ArgoCD project permissions to manage for an app you are adding to ArgoCD

Output Format:

<group>     <object_kind>

Sorted by object kind

eg.

v1                          ConfigMap
batch/v1beta1               CronJob
apps/v1                     Deployment
autoscaling/v1              HorizontalPodAutoscaler
extensions/v1beta1          Ingress
v1                          Namespace
policy/v1beta1              PodDisruptionBudget
scheduling.k8s.io/v1        PriorityClass
v1                          Service
v1                          ServiceAccount
apps/v1                     StatefulSet
storage.k8s.io/v1           StorageClass
autoscaling.k8s.io/v1beta2  VerticalPodAutoscaler
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file.yaml> <file2.yaml> ...]"

help_usage "$@"

#min_args 1 "$@"

awk '/^(api|kind)/{print $2}' "$@" |
# sed N joins every 2 lines
sed 'N;s/\n/ /' |
sort -k2 -u |
column -t
