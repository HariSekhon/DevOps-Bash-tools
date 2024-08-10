#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-10 12:32:19 +0300 (Sat, 10 Aug 2024)
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
Recursively finds all local Helm Charts and materializes the full resultant YAML in an adjacent file called helm.materialized.yaml in each directory

The runs 'pluto detect-files -d .' in each directory to detect deprecated API objects inherited from embedded Helm charts affecting your Kubernetes cluster upgrades

If you are using internal private Helm repos, you will need to add them to your machine before running this

Pluto is run per directory as a workaround for this recursion issue:

    https://github.com/FairwindsOps/pluto/issues/444

Parallelized for performance

Requires 'helm' and 'pluto' binaries to be in the \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

#min_args 1 "$@"
max_args 1 "$@"

dir="${1:-.}"

pluto_detect_helm_materialize(){
    chart_path="$1"
    echo "========================================"
    echo "$chart_path"
    pushd "$(dirname "$chart_path")" >/dev/null
    #if [[ "$chart" =~ ^eks- ]]; then
    #    echo "Skipping $chart"
    #    echo
    #    continue
    #fi
    helm dependency build
    helm template pluto-test .> "chart.materialized.yaml"
    echo "Materialized Helm YAML -> $PWD/chart.materialized.yaml"
    pluto detect-files -d .
    popd >/dev/null
    echo >&2
}
export -f pluto_detect_helm_materialize

find "$dir" -name Chart.yaml |
while read -r chart_path; do
    echo "pluto_detect_helm_materialize '$chart_path'"
done |
parallel
