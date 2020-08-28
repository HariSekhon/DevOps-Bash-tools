#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists GCP network resources deployed in the current GCP Project

Lists in this order:

    - Networks:
      - VPC Networks
      - Subnets
      - Routes
      - Addresses
      - Proxies
      - Routers
      - VPN Gateways
      - VPN Tunnels
      - Reservations
    - Firewall Rules & Forwarding Rules
    - DNS managed zones & verified domains
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"


# shellcheck disable=SC1090
type is_service_enabled &>/dev/null || . "$srcdir/gcp_service_apis.sh" >/dev/null


# Networking
cat <<EOF
# ============================================================================ #
#                              N e t w o r k i n g
# ============================================================================ #

EOF

echo "Networks:"
gcloud compute networks list
echo
echo "Addresses:"
gcloud compute addresses list
echo
echo "Target Pools:"
gcloud compute target-pools list
echo
echo "HTTP Proxies:"
gcloud compute target-http-proxies list
echo
echo "HTTPS Proxies:"
gcloud compute target-https-proxies list
echo
echo "SSL Proxies:"
gcloud compute target-ssl-proxies list
echo
echo "TCP Proxies:"
gcloud compute target-tcp-proxies list
echo
echo "URL Maps:"
gcloud compute url-maps list
echo
echo "Subnets:"
gcloud compute networks subnets list --sort-by=NETWORK
echo
echo "Routes:"
gcloud compute routes list
echo
echo "Routers:"
gcloud compute routers list
echo
echo "VPN Gateways:"
gcloud compute vpn-gateways list
echo
echo "VPN Tunnels:"
gcloud compute vpn-tunnels list
echo
echo "Reservations:"
gcloud compute reservations list


# Firewalls
cat <<EOF


# ============================================================================ #
#                               F i r e w a l l s
# ============================================================================ #

EOF

echo "Firewall Rules:"
gcloud compute firewall-rules list
# same output
#gcloud compute firewall-rules list --sort-by=NETWORK
echo
echo "Forwarding Rules:"
gcloud compute forwarding-rules list


# DNS
cat <<EOF


# ============================================================================ #
#                                     D N S
# ============================================================================ #

EOF

if is_service_enabled dns.googleapis.com; then
    gcloud dns managed-zones list
    echo
    gcloud domains list-user-verified
else
    echo "Cloud DNS API (dns.googleapis.com) is not enabled, skipping..."
fi
