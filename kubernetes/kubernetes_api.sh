#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-02 19:38:43 +0100 (Fri, 02 Aug 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# You might also be interested in find_active_kubernetes_api.py in DevOps Python tools repo - https://github.com/HariSekhon/DevOps-Python-tools

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by utils.sh usage()
# shellcheck disable=SC2034
usage_description="Auto-determines the Kubernetes API server and kube-system API Token to make curl calls to K8S easier"

# shellcheck source=lib/utils.sh
. "$srcdir/lib/utils.sh"

# shellcheck source=.bash.d/kubernetes.sh
. "$srcdir/.bash.d/kubernetes.sh"

# used by utils.sh usage()
# shellcheck disable=SC2034
usage_args="/path [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

curl_api_opts "$@"

token="$(k8s_get_token)"
api_server="$(k8s_get_api)"

path="$1"
shift || :

# could also extract the k8s certs from ~/.kube/config (not shown in kubectl config view, would have to json parse outside), and then do
# curl "$api_server" --cert encoded.crt --key encoded.key --cacert encoded-ca.crt

export TOKEN="$token"

# XXX: have to use -k to not verify the certificate here because often it is self-signed
#"$srcdir/../bin/curl_auth.sh" -k "$api_server$path" "$@"
"$srcdir/../bin/curl_auth.sh" "$api_server$path" "$@"
