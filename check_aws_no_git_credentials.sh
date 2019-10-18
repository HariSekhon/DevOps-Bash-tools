#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-18 13:57:12 +0100 (Fri, 18 Oct 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

section "AWS Git credentials scan"

start_time="$(start_timer)"

if git grep \
    -e 'AWS_ACCESS_KEY.*=' \
    -e 'AWS_SECRET_KEY.*=' \
    -e 'AWS_SESSION_TOKEN.*=' \
    -e 'aws_access_key_id.*=' \
    -e 'aws_secret_access_key.*=' \
    -e 'aws_session_token.*=' \
    "${1:-.}" |
        grep -v -e '\.bash\.d/aws.sh:' \
                -e "${0##*/}:" |
    grep .; then
    echo "DANGER: potential AWS credentials found in Git!!"
    exit 1
fi

time_taken "$start_time"
section2 "OK: no AWS credentials found in Git"
echo
