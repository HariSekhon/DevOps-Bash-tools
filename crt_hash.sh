#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-14 16:22:09 +0100 (Fri, 14 Aug 2020)
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
Uses OpenSSL to get the sha256 hash of a certificate crt file

Useful to generating the hash needed for joining a Kubernetes node to a cluster eg.

kubeadm join \\
    --token <token> \\
    --discovery-token-ca-cert-hash sha256:<hash> \\
    k8smaster:6443

To generate this actual command on a live cluster, run the adjacent kubeadm_join_cmd.sh script (which uses this script)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<file.crt>"

help_usage "$@"

min_args 1 "$@"

# eg. /etc/kubernetes/pki/ca.crt
crt_file="$1"

if ! [ -f "$crt_file" ]; then
    die "ERROR: file not found: $crt_file"
fi

openssl x509 -pubkey -in "$crt_file" |
openssl rsa -pubin -outform der 2>/dev/null |
openssl dgst -sha256 -hex |
sed 's/^.* //'
