#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-08-15 11:52:44 +0100 (Sat, 15 Aug 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh disable=SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Validates Jenkinsfiles in the directory given as an argument (defaults to \$PWD) using the Jenkins CLI

Requires a live Jenkins server so not called automatically in the CI framework of this repo
unless running within Jenkins CI job or the following environment variables are set:

If running manually then these environment variables must be set:

\$JENKINS_URL (default: http://localhost:8080)
        or
    \$JENKINS_HOST (default: localhost)
        and
    \$JENKINS_PORT (default: 8080)

\$JENKINS_USER_ID   / \$JENKINS_USER
\$JENKINS_API_TOKEN / \$JENKINS_TOKEN /\$JENKINS_PASSWORD

Only finds and checks files that match the name glob '*Jenkinsfile*' in the directory paths given, or under the current directory tree if no dirs are specified as args

Limitation: the validator doesn't recognized parameterized pipelines imported via a Jenkins Shared Library. Such valid Jenkinsfiles fail validation with this error: \"did not contain the 'pipeline' step'\"
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<Jenkinsfiles_dirs>"

help_usage "$@"

#min_args 1 "$@"

jenkinsfiles=()

for arg in "${@:-.}"; do
    if [ -d "$arg" ]; then
        jenkinsfiles+=( "$(find "${1:-.}" -maxdepth 3 -name '*Jenkinsfile*' | grep -v -e '\.groovy$')" )
    else
        jenkinsfiles+=("$arg")
    fi
done

if [ -z "${jenkinsfiles[*]}" ]; then
    # shellcheck disable=SC2317
    return 0 &>/dev/null ||
    exit 0
fi

section "J e n k i n s f i l e s"

start_time="$(start_timer)"

if [ -z "${JENKINS_URL:-}" ]; then
    export JENKINS_URL="${JENKINS_HTTPS:-http}://${JENKINS_HOST:-localhost}:${JENKINS_PORT:-8080}"
fi

JENKINS_URL="${JENKINS_URL%%/}"

#crumb="$("$srcdir/../bin/curl_auth.sh" -sS --fail "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumb')"

echo "Validating Jenkinsfiles:"
echo
while read -r jenkinsfile; do
    echo -n "$jenkinsfile => "
    #"$srcdir/../bin/curl_auth.sh" "$JENKINS_URL/pipeline-model-converter/validate" -sS --fail -X POST -F "jenkinsfile=<Jenkinsfile" -H "Jenkins-Crumb: $crumb"
    #"$srcdir/jenkins_api.sh" "/pipeline-model-converter/validate" -X POST -F "jenkinsfile=<Jenkinsfile"
    #"$srcdir/jenkins_api.sh" "/pipeline-model-converter/validate" -X POST -F "jenkinsfile=<$jenkinsfile"
    # 'export JENKINS_CLI_ARGS=-webSocket' is needed if Jenkins is behind a reverse proxy such as Kubernetes Ingress, otherwise Jenkins CLI hangs
    "$srcdir/../jenkins/jenkins_cli.sh" declarative-linter < "$jenkinsfile"
done <<< "$jenkinsfiles"

time_taken "$start_time"
section2 "Jenkinsfile validation SUCCEEDED"
echo
