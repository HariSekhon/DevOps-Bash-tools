#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-12 23:43:00 +0000 (Wed, 12 Feb 2020)
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
srcdir="$(dirname "$0")"

usage(){
    cat <<EOF

Script to query GitHub API

Automatically handles environment variables \$GITHUB_USER
and \$GITHUB_TOKEN / \$GITHUB_PASSWORD (the latter is deprecated)

EOF
    exit 3
}

for arg; do
    case "$arg" in
        -*)     usage
                ;;
    esac
done

export USER="${GITHUB_USER:-${USERNAME:-${USER}}}"
PASSWORD="${GITHUB_PASSWORD:-${GITHUB_TOKEN:-${PASSWORD:-}}}"

if [ -z "${PASSWORD:-}" ]; then
    PASSWORD="$(git remote -v | awk '/https:\/\/[[:alnum:]]+@/{print $2; exit}' | sed 's|https://||;s/@.*//')"
fi

export PASSWORD

if [ -n "${PASSWORD:-}"  ]; then
    echo "using authenticated access" >&2
fi

eval "$srcdir/curl_auth.sh" -sS --connect-timeout 3 "${CURL_OPTS:-}" "https://api.github.com$*"
