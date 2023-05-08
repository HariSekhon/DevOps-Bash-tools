#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: google.com
#
#  Author: Hari Sekhon
#  Date: 2021-01-27 17:00:21 +0000 (Wed, 27 Jan 2021)
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
Fetches and translates the remote host's SSL cert to human readable text using OpenSSL

Port defaults to 443 if not given

Uses adjacent script ssl_get_cert.sh
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="host[:port]"

help_usage "$@"

num_args 1 "$@"

host_port="$1"

if ! [[ "$host_port" =~ : ]]; then
    host_port="$host_port:443"
fi

"$srcdir/ssl_get_cert.sh" "$host_port" |
openssl x509 -noout -text
