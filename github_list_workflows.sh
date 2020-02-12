#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-02-12 16:21:52 +0000 (Wed, 12 Feb 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Script to get GitHub Workflows via the API
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

repo="${1:-${REPO:-}}"

if [ -z "$repo" ]; then
    repo="$(git remote -v | awk '{print $2}' | head -n1 | sed 's/[[:alnum:]]*@//; s,.*github.com[/:],,')"
fi

if [ -z "$repo" ]; then
    echo "usage: ${0##*/} <repo>"
    exit 3
fi

USER="${GITHUB_USER:-${USERNAME:-${USER}}}"
PASSWORD="${GITHUB_PASSWORD:-${GITHUB_TOKEN:-${PASSWORD}}}"

if ! [[ $repo =~ / ]]; then
    repo="$USER/$repo"
fi

if [ -n "${PASSWORD:-}"  ]; then
    echo "using authenticated access" >&2
fi

workflow_id="${2:-}"
if [ -n "$workflow_id" ]; then
    workflow_id="/$workflow_id"
fi

eval "$srcdir/curl_auth.sh" -sS --connect-timeout 3 "${CURL_OPTS:-}" "https://api.github.com/repos/$repo/actions/workflows$workflow_id"
