#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-28 15:16:18 +0000 (Sat, 28 Mar 2020)
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

config="$srcdir/setup/jenkins-docker-compose.yml"

if [ -n "${JENKINS_PASSWORD:-}" ]; then
    echo "using \$JENKINS_PASSWORD from environment" >&2
else
    # </dev/null stops this swallowing stdin which we need for jenkins_cli.sh create-job
    JENKINS_PASSWORD="$(docker-compose -f "$config" exec -T jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword </dev/null)"
fi

# if sourced, export JENKINS_PASSWORD, if subshell, echo it
#if [[ "$_" != "$0" ]]; then
    export JENKINS_PASSWORD
#else
    echo "$JENKINS_PASSWORD"
#fi
