#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-21 18:24:59 +0000 (Sat, 21 Mar 2020)
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

export PATH="$PATH:/usr/local/bin:"~/bin

target="${FLY_TARGET:-}"

opts=()
if [ -n "$target" ]; then
    opts+=(-t "$target")
fi

# check fly is in $PATH before we exec which would close the shell if called directly, losing the error message
# which checks for executable which command -v and type -P don't
# shellcheck disable=SC2230
if ! which fly &>/dev/null; then
    if [ -n "${CONCOURSE_URL:-}" ] ||
       [ -n "${CONCOURSE_HOST:-}" ]; then
        protocol="http"
        if [ -n "${CONCOURSE_SSL:-}" ]; then
            protocol=https
        fi
        # give priority to CONCOURSE_URL, otherwise CONCOURSE_HOST must exist and we can construct from there
        if [ -z "${CONCOURSE_URL:-}" ]; then
            CONCOURSE_URL="$protocol://$CONCOURSE_HOST:${CONCOURSE_PORT:-8080}"
        fi
        # this is in $PATH above
        dir=~/bin
        mkdir -pv "$dir"
        os="$(uname -s | tr '[:upper:]' '[:lower:]')"
        echo "Downloading fly for OS = $os" >&2
        wget -cO "$dir/fly" "http://$CONCOURSE_HOST:$CONCOURSE_PORT/api/v1/cli?arch=amd64&platform=$os"
        chmod +x "$dir/fly"
        echo
    else
        echo "'fly' command not found in \$PATH ($PATH)" >&2
        echo >&2
        echo "\$CONCOURSE_URL and \$CONCOURSE_HOST are both unset, cannot download from concourse automatically" >&2
        exit 1
    fi
fi

exec fly "${opts[@]}" "$@"
