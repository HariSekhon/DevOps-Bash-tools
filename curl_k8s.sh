#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-08-02 19:38:43 +0100 (Fri, 02 Aug 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# You might also be interested in find_active_kubernetes_api.py in DevOps Python tools repo - https://github.com/HariSekhon/DevOps-Python-tools

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# used by utils.sh usage()
# shellcheck disable=SC2034
usage_description="Auto-determines the Kubernetes API server and kube-system API Token to make curl calls to K8S easier"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090
. "$srcdir/.bash.d/k8s.sh"

# used by utils.sh usage()
# shellcheck disable=SC2034
usage_args="/path <curl_options>"

if [ $# -lt 1 ]; then
    usage
fi

for x in "$@"; do
    case "$x" in
        -h|--help) usage
        ;;
    esac
done

check_bin curl

token="$(k8s_get_token)"
api_server="$(k8s_get_api)"

path="${1:-}"

shift

curl -k --header "Authorization: Bearer $token" "$api_server$path" "$@"
