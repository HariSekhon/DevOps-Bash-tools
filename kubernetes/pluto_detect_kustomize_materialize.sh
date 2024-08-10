#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2023-01-30 14:26:58 +0000 (Mon, 30 Jan 2023)
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
Recursively finds all Kustomizations and materializes the full resultant YAML in an adjacent file called kustomization.materialized.yaml in each directory

The runs 'pluto detect-files -d .' in each directory to detect deprecated API objects inherited from embedded Helm charts affecting your Kubernetes cluster upgrades

Pluto is run per directory as a workaround for this recursion issue:

    https://github.com/FairwindsOps/pluto/issues/444

Parallelized for performance, with Helm support enabled.

Requires 'kustomize' and 'pluto' binaries to be in the \$PATH - will attempt to install them if not found
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<dir>]"

help_usage "$@"

#min_args 1 "$@"
max_args 1 "$@"

dir="${1:-.}"

for x in kustomize pluto; do
    if ! type -P "$x" &>/dev/null; then
        "$srcdir/../install_$x.sh"
    fi
done

pluto_detect_kustomize_materialize(){
    kustomization_path="$1"
    hr
    timestamp "$kustomization_path"
    pushd "$(dirname "$kustomization_path")" >/dev/null
    #if [[ "$kustomization" =~ ^eks- ]]; then
    #    echo "Skipping $kustomization"
    #    echo
    #    continue
    #fi
    kustomize build --enable-helm > "kustomization.materialized.yaml"
    timestamp "Materialized Kustomize YAML -> $PWD/kustomization.materialized.yaml"
    pluto detect-files -d .
    popd >/dev/null
    echo >&2
}
export -f pluto_detect_kustomize_materialize
export -f hr
export -f timestamp

find "$dir" -name kustomization.yaml |
while read -r kustomization_path; do
    echo "pluto_detect_kustomize_materialize '$kustomization_path'"
done |
parallel
