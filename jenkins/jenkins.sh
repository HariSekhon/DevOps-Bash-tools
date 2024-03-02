#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-28 11:49:22 +0000 (Sat, 28 Mar 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Start a quick local Concourse CI

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/git.sh"

# shellcheck disable=SC2034
usage_description="
Boots Jenkins CI in Docker, and builds the current repo

- boots Jenkins container in Docker
- installs plugins
- prints admin credentials
- creates job from \$PWD/setup/jenkins-job.xml
  - using pipeline from \$PWD/Jenkinsfile
- enables job
- builds job
- prints Jenkins UI URL and opens it in browser

    ${0##*/} [up]

    ${0##*/} down

    ${0##*/} ui     - prints the Jenkins Server URL and automatically opens in browser

Idempotent, you can re-run this and continue from any stage

See Also:

    jenkins_cli.sh - this script makes heavy use of it to handle API calls with authentication as part of the setup
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[ up | down | ui ]"

help_usage "$@"

export JENKINS_HOST="${DOCKER_HOST:-localhost}"
export JENKINS_PORT=8080

export JENKINS_URL="http://$JENKINS_HOST:$JENKINS_PORT"
cli="$srcdir/jenkins_cli.sh"

#repo="${PWD##*/}"
#git_repo="$(git remote -v | grep github.com | sed 's/.*github.com/https:\/\/github.com/; s/ .*//')"
git_repo="$(git_repo)"
repo="${git_repo##*/}"
job="$repo"
job_xml="setup/jenkins-job.xml"

Jenkinsfile=Jenkinsfile

export COMPOSE_PROJECT_NAME="bash-tools"
export COMPOSE_FILE="$srcdir/../docker-compose/jenkins.yml"

plugins_txt="$srcdir/../setup/jenkins-plugins.txt"

if ! type docker-compose &>/dev/null; then
    "$srcdir/../install/install_docker_compose.sh"
fi

action="${1:-up}"
shift || :

print_creds(){
    password="$("$srcdir/jenkins_password.sh" || :)"

    if [ -n "$password" ]; then
    cat <<EOF

Jenkins Login username:  admin
Jenkins Login password:  $password

EOF
    fi
}

if [ "$action" = up ]; then
    timestamp "Booting Jenkins:"
    docker-compose up -d "$@"
    echo >&2
elif [ "$action" = restart ]; then
    docker-compose down
    echo >&2
    exec "${BASH_SOURCE[0]}" up
elif [ "$action" = ui ]; then
    echo "Jenkins URL:  $JENKINS_URL"
    print_creds
    open "$JENKINS_URL"
    exit 0
else
    docker-compose "$action" "$@"
    echo >&2
    exit 0
fi

when_jenkins_up(){
    when_url_content 90 "$JENKINS_URL/login" '(?i:jenkins|hudson)'
    echo
}

when_jenkins_up

timestamp "Installing plugins"
# would be slow to do this via jenkins-cli
# sed 's/#.*//; s/:.*//; /^[[:space:]]*$/d' setup/jenkins-plugins.txt | while read plugin; do jenkins_cli.sh install-plugin "$plugin"; done
#
# Old: deprecated, but still more portable across existing versions
docker-compose exec -T jenkins-server /usr/local/bin/install-plugins.sh < "$plugins_txt" ||
# New: later switch to
{
    docker-compose cp "$plugins_txt" jenkins-server:/ &&
    docker-compose exec -T jenkins-server /bin/jenkins-plugin-cli -f "${plugins_txt##*/}"
} || :  # exits 1 warning about plugins already existing
echo

# if this fails then the the CLI commands will also fail because they use a similar mechanism to find the admin password from the container to authenticate with the Jenkins API
print_creds

if ! "$cli" list-plugins | grep -q .; then
    timestamp "Restarting Jenkins to pick up plugins:"
    #"$cli" restart
    #when_ports_down 300 "$JENKINS_HOST" "$JENKINS_PORT"
    docker-compose restart jenkins-server "$@"

    when_jenkins_up
fi

SECONDS=0
while [ "$SECONDS" -lt 300 ]; do
    if "$cli" list-plugins | grep -q .; then
        echo
        break
    fi
    timestamp "waiting for Jenkins to finish initializing and list plugins"
    sleep 1
done

for filename in "$Jenkinsfile" "$job_xml"; do
    if ! [ -f "$filename" ]; then
        timestamp "Jenkins configuration file '$filename' not found"
        echo >&2
        timestamp "Skipping loading missing pipeline"
        echo >&2
        timestamp "Re-run this from the root directory of a repo containing '$Jenkinsfile' and '$job_xml' to auto-load a pipeline"
        exit 0
    fi
done

# XXX: this fails if the plugins haven't been loaded properly
# XXX: you'll also get this error trying to run the job's pipeline:
#      java.lang.NoSuchMethodError: No such DSL method 'pipeline' found among steps
timestamp "Validating Jenkinsfile"
"$cli" declarative-linter < "$Jenkinsfile"
echo

timestamp "Creating / Updating job - $job:"
if "$cli" list-jobs | grep -q "^$job$"; then
    timestamp "job already exists, updating..."
    "$cli" update-job "$job" < "$job_xml"
else
    timestamp "job does not exist, creating..."
    "$cli" create-job "$job" < "$job_xml"
fi
echo

timestamp "Enabling job - $job:"
"$cli" enable-job "$job"
echo

# -f waits for build
# -v prints build contents
timestamp "Building job - $job and tailing output:"
"$cli" build -f -v "$job"

#echo "Tailing last build:"
#"$cli" console "$job" -f
