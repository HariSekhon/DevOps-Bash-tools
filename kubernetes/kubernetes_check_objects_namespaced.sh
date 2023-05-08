#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-13 08:08:02 +0100 (Sat, 13 Aug 2022)
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
Checks Kubernetes yaml for objects without namespaces specified, which can easily result in deployments to the wrong namespace

Useful to find common mistakes in YAMLs or Helm chart templates pulled through Kustomize that don't have namespaces unless you specify it in the kustomization.yaml

Takes yaml as standard input or file arguments

Some objects are cluster-wide so should be ignored, but most objects should be namespaced. Will query your current Kubernetes cluster
for such objects, and if successful will exclude them to reduce noise

Requires kubectl to be installed and configured, as well as 'yq' version 4.18.1+
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<file1.yaml> <file2.yaml> ...]"

help_usage "$@"

yaml_objects_without_namespace="$(yq 'select(.metadata.namespace == null)' -- "$@")"

# -o name is not usable for kind filtering later, and output doesn't support any other column as of 1.18, so must extract the KIND last column
objects_not_namespaced="$(kubectl api-resources --namespaced=false --no-headers | awk '{print $NF}' 2>/dev/null || :)"

if [ -n "$objects_not_namespaced" ]; then
    regex="$(tr '\n' '|' <<< "$objects_not_namespaced" | sed 's/|$//')"
    yaml_objects_without_namespace="$(yq 'select(.kind | test("^('"$regex"')$") | not)' <<< "$yaml_objects_without_namespace")"
fi

num_objects_without_namespace="$(grep -c '^kind:' <<< "$yaml_objects_without_namespace" || :)"

if [ "$num_objects_without_namespace" = 0 ]; then
    echo "OK: all objects have a namespace specified" >&2
else
    echo "WARNING: $num_objects_without_namespace objects detected without namespace:" >&2
    echo >&2
    echo "$yaml_objects_without_namespace"
    echo >&2
    echo "WARNING: $num_objects_without_namespace objects detected without namespace!" >&2
    exit 1
fi
