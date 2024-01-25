#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: google.com
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
Dumps the SSL certificate blocks for hosts given as arguments, using OpenSSL

Port defaults to 443 if not given
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="host1[:port] [ host2:[:port]] [host3[:port]] ... ]"

help_usage "$@"

min_args 1 "$@"

for host in "$@"; do
    host_port="$host"
    if ! [[ "$host_port" =~ : ]]; then
        host_port="$host_port:443"
    fi
    #if ! openssl s_client -connect "$host_port" </dev/null 2>/dev/null | sed -n '/BEGIN/,/END/p'; then
    #    echo "ERROR connecting to $host_port"
    #    exit 1
    #fi
    # sed returns 1
    openssl s_client -connect "$host_port" </dev/null 2>/dev/null | sed -n '/BEGIN/,/END/p' || :
done
