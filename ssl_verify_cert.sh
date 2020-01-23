#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-04-11 18:48:01 +0100 (Thu, 11 Apr 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Verifies the HTTPS SSL certificate of each host argument
#
# For a much better version of this see check_ssl_cert.pl in the Advanced Nagios Plugins Collection:
#
# check_ssl_cert.pl checks expiry days remaining, domain, SAN + SNI
#
# https://github.com/harisekhon/nagios-plugins

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if [ $# -lt 1 ]; then
    echo "usage: ${0##*/} host[:port] [host2[:port]] ..."
    echo
    exit 3
fi

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
