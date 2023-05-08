#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-06-03 18:11:23 +0100 (Thu, 03 Jun 2021)
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
Curls the current Kubernetes cluster's Nginx Ingress controller's external IP address using the given URL

Useful for debugging Ingress Routing + SSL certificates directly by bypassing DNS -> CDN addresses such as Cloudflare

Requires kubectl to be installed and configured with the target cluster selected as the current context
in order to find the Ingress Controller's external IP address

Tips:

    - Make sure to specify the correct prefix eg. https:// and path suffix so that you don't hit a 302 redirect back to the CDN address
    - Use '-kv' curl switches to see the cert and header info

Prints the curl command inferred as it is used so you can see what you're doing
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<url> [<curl_options>]"

help_usage "$@"

min_args 1 "$@"

url="$1"
shift || :

shopt -s nocasematch

if ! [[ "$url" =~ :// ]]; then
    url="http://$url"
fi

#shopt -s extglob
#host="${url#http?(s)://}"
#shopt -u extglob

host="${url#http://}"
host="${host#https://}"

# strip /path
host="${host%%[;/]*}"

# if url prefix doesn't strip successfully, the above line results in host='https:'
if [[ "$host" =~ : ]]; then
    die "Host parse failure from url: '$url', inferred host as '$host'"
fi

# TODO: extend this to detect and return the IPs of other ingress controllers if deployed eg. older nginx-ingress, traefik, haproxy etc.
#
# XXX: on some clusters appears under '.spec.loadBalancerIP' and others '.status.loadBalancer.ingress[].ip' so try both
IP="$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o 'jsonpath={.spec.loadBalancerIP}{.status.loadBalancer.ingress[].ip}')"
if [ -z "$IP" ]; then
    # support_msg defined in lib/utils-bourne.sh
    # shellcheck disable=SC2154
    die "Failed to determine Kubernetes ingress IP address - possibly not using ingress-nginx, in which case this code needs extending. $support_msg"
fi

if [[ "$url" =~ ^http:// ]]; then
    port=80
else
    port=443
fi

# this works for ingress path routing but not SSL verification, forcing you to use -k and not debugging the certificate
#url="${url/:\/\/$host/://$IP}"
#curl -H "Host: $host" "$url" "$@"

cmd=(curl "$url" --resolve "$host:$port:$IP" "$@")
echo "${cmd[*]}"
"${cmd[@]}"
