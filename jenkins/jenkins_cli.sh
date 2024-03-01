#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: help
#
#  Author: Hari Sekhon
#  Date: 2020-03-28 12:56:30 +0000 (Sat, 28 Mar 2020)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Wraps the Jenkins CLI and handles using various environment variables for connection and authentication

Downloads the jenkins-cli.jar from the \$JENKINS_URL on first run

Configuration Environment Variables:

(in order of descending precedence and matches jenkins-cli.jar)

    JENKINS_URL  - https://jenkins.domain.com
        or
    JENKINS_HOST
    JENKINS_PORT
    JENKINS_SSL     (any value enables SSL)

    JENKINS_USER_ID
    JENKINS_TOKEN
    (tries a username of admin if neither of the above two variables are set)

    JENKINS_API_TOKEN
    JENKINS_TOKEN
    JENKINS_PASSWORD
    (will attempt to find the password via jenkins_password.sh as a last ditch attempt if not set)

    JENKINS_CLI_ARGS    (optional - any switches you want passed to the jenkins-cli.jar)

IMPORTANT: if Jenkins is behind a reverse proxy such as Kubernetes Ingress, you will probably need to add the '-webSocket' argument, otherwise it Jenkins CLI will hang

      Tip: set this in JENKINS_CLI_ARGS to not have to specify it every time

Usage:

    jenkins_cli.sh --help


Everything else is passed directly to jenkins-cli.jar


 Examples:

   # See all Jenkins CLI options:

       jenkins_cli.sh help

   # Get Jenkins version:

       jenkins_cli.sh version

   # Show your authenticated user:

       jenkins_cli.sh who-am-i

   # List Plugins:

       jenkins_cli.sh list-plugins

   # List Jobs (Pipelines):

       jenkins_cli.sh list-jobs

   # List Credential Providers:

       jenkins_cli.sh list-credentials-providers

   # List Credentials in the default global in-built credential store:

       jenkins_cli.sh list-credentials system::system::jenkins

   # Dump all Credentials configurations in the default in-build credentials store in XML format:

       jenkins_cli.sh list-credentials-as-xml system::system::jenkins
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

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

JENKINS_USER="${JENKINS_USER_ID:-${JENKINS_USER:-admin}}"

JENKINS_PASSWORD="${JENKINS_API_TOKEN:-${JENKINS_TOKEN:-${JENKINS_PASSWORD:-}}}"
if [ -z "${JENKINS_PASSWORD:-}" ]; then
    JENKINS_PASSWORD="$("$srcdir/jenkins_password.sh" || :)"
fi

if ! [ -s "$jar" ]; then
    if type -P wget &>/dev/null; then
        wget -cO "$jar" "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
    else
        curl -sSf >"$jar" "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
    fi
fi

# -s "$JENKINS_URL" is implicit
# cannot load jenkins job from stdin if doing this
#java -jar "$jar" -auth @/dev/fd/0 "$@" <<< "$JENKINS_USER:$JENKINS_PASSWORD"
#java -jar "$jar" -auth "$JENKINS_USER:$JENKINS_PASSWORD" "$@"

# want splitting
# shellcheck disable=SC2086
java -jar "$jar" -s "$JENKINS_URL" -auth @<(cat <<< "$JENKINS_USER:$JENKINS_PASSWORD") ${JENKINS_CLI_ARGS:-} "$@"
