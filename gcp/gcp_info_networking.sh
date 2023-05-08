#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-13 19:38:39 +0100 (Thu, 13 Aug 2020)
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
. "$srcdir/lib/gcp.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Lists GCP network resources deployed in the current GCP Project

Lists in this order:

    - Networks:
      - VPC Networks
      - Addresses
      - Proxies
      - Subnets
      - Routers
      - Routes
      - VPN Gateways
      - VPN Tunnels
      - Reservations
    - Firewall Rules & Forwarding Rules
    - DNS managed zones & verified domains

Can optionally specify a project id using the first argument, otherwise uses currently configured project

$gcp_info_formatting_help
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<project_id>]"

help_usage "$@"

check_bin gcloud

if [ $# -gt 0 ]; then
    project_id="$1"
    shift || :
    export CLOUDSDK_CORE_PROJECT="$project_id"
fi


# shellcheck disable=SC1090,SC1091
type is_service_enabled &>/dev/null || . "$srcdir/gcp_service_apis.sh" >/dev/null


# Networking
cat <<EOF
# ============================================================================ #
#                              N e t w o r k i n g
# ============================================================================ #

EOF

gcp_info "Networks"               gcloud compute networks list

gcp_info "Addresses"              gcloud compute addresses list

gcp_info "Target Pools"           gcloud compute target-pools list

gcp_info "HTTP Proxies"           gcloud compute target-http-proxies list

gcp_info "HTTPS Proxies"          gcloud compute target-https-proxies list

gcp_info "SSL Proxies"            gcloud compute target-ssl-proxies list

gcp_info "TCP Proxies"            gcloud compute target-tcp-proxies list

gcp_info "URL Maps"               gcloud compute url-maps list

gcp_info "Subnets"                gcloud compute networks subnets list --sort-by=NETWORK,REGION

gcp_info "Subnets usable for GKE" gcloud container subnets list-usable --sort-by=NETWORK,REGION

gcp_info "Routers"                gcloud compute routers list

gcp_info "Routes"                 gcloud compute routes list

gcp_info "VPN Gateways"           gcloud compute vpn-gateways list

gcp_info "VPN Tunnels"            gcloud compute vpn-tunnels list

gcp_info "Reservations"           gcloud compute reservations list


# Firewalls
cat <<EOF


# ============================================================================ #
#                               F i r e w a l l s
# ============================================================================ #

EOF

gcp_info "Firewall Rules"   gcloud compute firewall-rules list
                            # same output
                            #gcloud compute firewall-rules list --sort-by=NETWORK

gcp_info "Forwarding Rules" gcloud compute forwarding-rules list


# DNS
cat <<EOF


# ============================================================================ #
#                                     D N S
# ============================================================================ #

EOF

if is_service_enabled dns.googleapis.com; then
    gcp_info "DNS Managed Zones" gcloud dns managed-zones list

    gcp_info "Domains verified"  gcloud domains list-user-verified
else
    echo "Cloud DNS API (dns.googleapis.com) is not enabled, skipping..."
fi
