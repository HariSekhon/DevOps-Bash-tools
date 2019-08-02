#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-01-02 21:08:12 +0000 (Wed, 02 Jan 2019)
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

# used by utils.sh usage()
# shellcheck disable=SC2034
usage_description="Generates a ram only netrc file from .ssh/known_hosts and calls curl with it to avoid credentials being logged in environments that log every command and argument"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# used by utils.sh usage()
# shellcheck disable=SC2034
usage_args="<curl_options>"

if [ $# -lt 1 ]; then
    usage
fi

for x in "$@"; do
    case "$x" in
        -h|--help) usage
        ;;
    esac
done

check_bin curl

USERNAME="${USERNAME:-$USER}"

if [ -z "${PASSWORD:-}" ]; then
    read -r -s -p 'password: ' PASSWORD
    echo
fi

# doesn't work
#netrc_content="default login $USERNAME password $PASSWORD"

hosts="$(awk '{print $1}' < ~/.ssh/known_hosts 2>/dev/null | sed 's/,.*//' | sort -u)"

# use built-in echo if availble, cat is slow with ~1000 .ssh/known_hosts
if help echo &>/dev/null; then
    netrc_contents="$(for host in $hosts; do echo "machine $host login $USERNAME password $PASSWORD"; done)"
else
    # slow fallback with lots of forks
    netrc_contents="$(for host in $hosts; do cat <<< "machine $host login $USERNAME password $PASSWORD"; done)"
fi

curl --netrc-file <(cat <<< "$netrc_contents") "$@"
