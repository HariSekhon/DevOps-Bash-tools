#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: google.com yahoo.com
#
#  Author: Hari Sekhon
#  Date: 2019-04-11 18:48:01 +0100 (Thu, 11 Apr 2019)
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

# shellcheck disable=SC2034
usage_description="
Verifies the SSL certificate for each host given as arguments, using OpenSSL

Port defaults to 443 if not specified


For a much better version of this see check_ssl_cert.pl in the Advanced Nagios Plugins Collection:

    check_ssl_cert.pl - checks Expiry days remaining, Domain, Subject Alternative Names, SNI

    https://github.com/HariSekhon/Nagios-Plugins
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="host1[:port] [ host2:[:port]] [host3[:port]] ... ]"

help_usage "$@"

min_args 1 "$@"

exitcode=0

# otherwise will silently fail getting openssl output on incorrect host
set +o pipefail

for host in "$@"; do
    host_port="$host"
    if ! [[ "$host_port" =~ : ]]; then
        host_port="$host_port:443"
    fi
    # openssl returns 1 regardless of whether host/cert is valid/invalid
    output="$(openssl s_client -connect "$host_port" < /dev/null 2>/dev/null |
              grep Verify |
              sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -n "${output:-}" ]; then
        echo "$output"
        if ! [[ "$output" =~ Verify[[:space:]]*return[[:space:]]*code:[[:space:]]*0 ]]; then
            exitcode=1
        fi
    else
        echo "Failed to connect"
        if [ $exitcode -eq 0 ]; then
            exitcode=1
        fi
    fi
done
