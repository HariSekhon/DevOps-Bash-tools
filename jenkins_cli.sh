#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-28 12:56:30 +0000 (Sat, 28 Mar 2020)
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

# could set this to DNS CNAME 'jenkins', but often these says we run in docker
DEFAULT_JENKINS_HOST=localhost
DEFAULT_JENKINS_PORT=8080

java="${JAVA:-java}"
jar="$srcdir/jenkins-cli.jar"

# shellcheck disable=SC2230
if ! which "$java" &>/dev/null; then
    echo "$java not found in PATH (\$PATH)"
    exit 1
fi

if [ -z "${JENKINS_URL:-}" ]; then
    host="${JENKINS_HOST:-${HOST:-$DEFAULT_JENKINS_HOST}}"
    port="${JENKINS_PORT:-${PORT:-$DEFAULT_JENKINS_PORT}}"
    http="http"
    if [ -n "${JENKINS_SSL:-}" ]; then
        http="https"
    fi
    export JENKINS_URL="$http://$host:$port"
fi

JENKINS_USER="${JENKINS_USER:-admin}"

if [ -z "${JENKINS_PASSWORD:-}" ]; then
    JENKINS_PASSWORD="$("$srcdir/jenkins_password.sh" || :)"
fi

if ! [ -s "$jar" ]; then
    wget -O "$jar" "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
fi

# -s "$JENKINS_URL" is implicit
# cannot load jenkins job from stdin if doing this
#java -jar "$jar" -auth @/dev/fd/0 "$@" <<< "$JENKINS_USER:$JENKINS_PASSWORD"
#java -jar "$jar" -auth "$JENKINS_USER:$JENKINS_PASSWORD" "$@"
java -jar "$jar" -auth @<(cat <<< "$JENKINS_USER:$JENKINS_PASSWORD") "$@"
