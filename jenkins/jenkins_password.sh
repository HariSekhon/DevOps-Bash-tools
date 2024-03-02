#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-28 15:16:18 +0000 (Sat, 28 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Gets the Jenkins initial admin password out of the Docker Compose jenkins-server container or Kubernetes jenkins helm deployment secret

# For docker-compose you might need the compose project name matching the instantiation, eg.
#
#   export COMPOSE_PROJECT_NAME="bash-tools"

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

config="$srcdir/../docker-compose/jenkins.yml"

if [ -n "${JENKINS_PASSWORD:-}" ]; then
    echo "using \$JENKINS_PASSWORD from environment" >&2

# weird bug on macOS 14.1 where grep -q is no longer matching but grep is, so >/dev/null instead
elif docker ps 2>/dev/null | grep jenkins-server >/dev/null; then

    # </dev/null stops this swallowing stdin which we need for jenkins_cli.sh create-job
    JENKINS_PASSWORD="$(docker-compose -f "$config" exec -T jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword </dev/null)"

#elif kubectl get po -n jenkins -l app.kubernetes.io/component=jenkins-controller -o name 2>/dev/null | grep -q .; then
    #pod="$(kubectl get po -n jenkins -l app.kubernetes.io/component=jenkins-controller -o name)"
    # doesn't exist
    #JENKINS_PASSWORD="$(kubectl exec -ti -n jenkins "$pod" -- cat /var/jenkins_home/secrets/initialAdminPassword)"

elif kubectl get secret -n jenkins jenkins &>/dev/null; then
    JENKINS_PASSWORD="$(kubectl get secret -n jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)"

elif [ -f /var/jenkins_home/secrets/initialAdminPassword ]; then
    JENKINS_PASSWORD="$(cat /var/jenkins_home/secrets/initialAdminPassword)"
fi

if [ -z "${JENKINS_PASSWORD:-}" ]; then
    echo "ERROR: failed to determine JENKINS_PASSWORD from environment, docker-compose or kubernetes" >&2
    exit 1
fi

# if sourced, export JENKINS_PASSWORD, if subshell, echo it
#if [[ "$_" != "$0" ]]; then
    export JENKINS_PASSWORD
#else
    echo -n "$JENKINS_PASSWORD"  # no newline so we can pipe straight to pbcopy / xclip or similar
#fi
