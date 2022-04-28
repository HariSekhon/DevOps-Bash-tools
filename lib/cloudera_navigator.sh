#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-23 15:08:10 +0000 (Thu, 23 Jan 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Quick lib to be sourced for auto-populating Cloudera Navigator details in a script

# Tested on Cloudera Enterprise 5.10

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

CLOUDERA_NAVIGATOR_HOST="${CLOUDERA_NAVIGATOR_HOST:-${CLOUDERA_NAVIGATOR:-${CLOUDERA_HOST:-${HOST:-}}}}"
CLOUDERA_NAVIGATOR_PORT="${CLOUDERA_NAVIGATOR_PORT:-${CLOUDERA_PORT:-${PORT:-7186}}}"

CLOUDERA_NAVIGATOR_HOST="${CLOUDERA_NAVIGATOR_HOST##*://}"
CLOUDERA_NAVIGATOR_HOST="${CLOUDERA_NAVIGATOR_HOST%%/*}"
CLOUDERA_NAVIGATOR_HOST="${CLOUDERA_NAVIGATOR_HOST%%:*}"

if [ -z "$CLOUDERA_NAVIGATOR_HOST" ]; then
    read -r -p 'Enter Cloudera Navigator host URL: ' CLOUDERA_NAVIGATOR_HOST
fi

export USER="${CLOUDERA_NAVIGATOR_USER:-${CLOUDERA_USER:-${USER:-}}}"
export PASSWORD="${CLOUDERA_NAVIGATOR_PASSWORD:-${CLOUDERA_PASSWORD:-${PASSWORD:-}}}"

CLOUDERA_NAVIGATOR="http://$CLOUDERA_NAVIGATOR_HOST:$CLOUDERA_NAVIGATOR_PORT"

if [ -n "${CLOUDERA_NAVIGATOR_SSL:-}" ]; then
    CLOUDERA_NAVIGATOR="https://${CLOUDERA_NAVIGATOR#*://}"
    if [[ "$CLOUDERA_NAVIGATOR" =~ :7186$ ]]; then
        CLOUDERA_NAVIGATOR="${CLOUDERA_NAVIGATOR%:7186}:7187"
    fi
fi

# shellcheck disable=SC2034
# Navigator expects timestamp in millis
now_timestamp="$(date +%s000)"
