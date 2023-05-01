#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-03-16 18:40:25 +0000 (Wed, 16 Mar 2022)
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
Creates a Kuberbetes secret from key=value args or stdin

If no third or more arguments are given, reads environment variables from standard input, one per line in 'key=value' format or 'export key=value' shell format

Examples:

    ${0##*/} mynamespace mysecret AWS_ACCESS_KEY_ID=AKIA...

    echo AWS_ACCESS_KEY_ID=AKIA... | ${0##*/} mynamespace mysecret


    Loads both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY via stdin:

        aws_csv_creds.sh credentials_exported.csv | ${0##*/} mynamespace mysecret


See Also:

    kubectl_secret_values.sh - dumps all key value pairs, base64 decoded, for a given Kubernetes secret



Requires kubectl to be installed and available in the \$PATH
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<k8s_namespace> <k8s_secret> [<key1>=<value1> <key2>=<value2> ...]"

help_usage "$@"

min_args 2 "$@"

namespace="$1"
secret_name="$2"
shift || :
shift || :

kube_config_isolate

key_values=()

add_kv(){
    local key_value="$1"
    parse_export_key_value "$key_value"
    key_values+=("--from-literal=$key=$value")
}


if [ $# -gt 0 ]; then
    for arg in "$@"; do
        add_kv "$arg"
    done
else
    while read -r line; do
        add_kv "$line"
    done
fi

kubectl create secret generic -n "$namespace" "$secret_name" "${key_values[@]}"
