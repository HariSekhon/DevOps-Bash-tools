#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-09-02 18:42:38 +0100 (Wed, 02 Sep 2020)
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
Lists the Cloudflare IPv4 and/or IPv6 CIDR ranges via the Cloudflare API
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[--ipv4 / --ipv6]"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_switches="
   --ipv4           Output only IPv4 CIDR ranges
   --ipv6           Output only IPv6 CIDR ranges
"

for arg; do
    case "$arg" in
        --ipv4)     IPV4_ONLY=1
                    ;;
        --ipv6)     IPV6_ONLY=1
                    ;;
    esac
done

if [ -n "${IPV4_ONLY:-}" ] &&
   [ -n "${IPV6_ONLY:-}" ]; then
    usage "IPv4 and IPv6 filters are mutually exclusive"
fi

help_usage "$@"

#min_args 1 "$@"

"$srcdir/cloudflare_api.sh" ips |
jq -r '.result.ipv4_cidrs[], .result.ipv6_cidrs[]' |
if [ -n "${IPV4_ONLY:-}" ]; then
    grep -v -e '[:alpha:]' -e ':'
elif [ -n "${IPV6_ONLY:-}" ]; then
    grep -e '[:alpha:]' -e ':'
else
    cat
fi
