#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-14 16:30:08 +0100 (Fri, 14 Aug 2020)
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
Generates the kubeadm join command for an already existing Kubernetes cluster where the initial kubeadm init join command token has already expired

Determines the certificate hash, and generates a new temporary token with which to join

kubeadm is assumed to be working and available in the \$PATH

Tested on Kubernetes 1.18.1
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[options]

-m --master     Master host address (default: local hostname/fqdn)
-p --port       Master port (default: 6443)
-c --crt        CA crt file (default: /etc/kubernetes/pki/ca.crt)
"

help_usage "$@"

#min_args 1 "$@"

# defaults
master="$(hostname -f)"
port="6443"
ca_crt="/etc/kubernetes/pki/ca.crt"

while [ $# -gt 0 ]; do
    case "$1" in
      -m|--master)  master="$2"
                    shift
                    ;;
      -p|--port)    port="$2"
                    shift
                    ;;
         -c|--crt)  ca_crt="$2"
                    shift
                    ;;
                *)  usage
                    ;;
    esac
    shift
done

if ! is_int "$port"; then
    usage "port given is not an integer: $port"
fi

# ca_crt path validated in here
crt_hash="$("$srcdir/../bin/crt_hash.sh" "$ca_crt")"

token="$(kubeadm token create)"

cat <<EOF
kubeadm join \\
    --token "$token" \\
    --discovery-token-ca-cert-hash "sha256:$crt_hash" \\
    "$master":$port
EOF
