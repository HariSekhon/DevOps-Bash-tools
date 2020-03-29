#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-03-28 11:49:22 +0000 (Sat, 28 Mar 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Start a quick local Concourse CI

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

#NUM_AGENTS=1

host=localhost
port=8080
server="http://$host:$port"
#api="$server/go/api"
cli="$srcdir/jenkins_cli.sh"

#repo="${PWD##*/}"
git_repo="$(git remote -v | grep github.com | sed 's/.*github.com/https:\/\/github.com/; s/ .*//')"
repo="${git_repo##*/}"
job="$repo"
job_xml="setup/jenkins-job.xml"

Jenkinsfile=Jenkinsfile

config="$srcdir/setup/jenkins-docker-compose.yml"
plugins_txt="$srcdir/setup/jenkins-plugins.txt"

for filename in "$Jenkinsfile" "$job_xml"; do
    if ! [ -f "$job_xml" ]; then
        echo "Jenkins configuration '$filename' not found - did you run this from the root of a standard repo?"
        exit 1
    fi
done

if ! type docker-compose &>/dev/null; then
    "$srcdir/install_docker_compose.sh"
fi

action="${1:-up}"
shift || :

opts=""
if [ "$action" = up ]; then
    opts="-d"
fi

echo "Booting Jenkins docker:"
docker-compose -f "$config" "$action" $opts "$@"
echo
if [ "$action" = down ]; then
    exit 0
fi

when_jenkins_up(){
    when_url_content "$server" '(?i:jenkins|hudson)'
    echo
}

when_jenkins_up

echo "Installing plugins"
# would be slow to do this via jenkins-cli
# sed 's/#.*//; s/:.*//; /^[[:space:]]*$/d' setup/jenkins-plugins.txt | while read plugin; do jenkins_cli.sh install-plugin "$plugin"; done
docker-compose -f "$config" exec -T jenkins-server /usr/local/bin/install-plugins.sh < "$plugins_txt"
echo

password="$("$srcdir/jenkins_password.sh" || :)"

if [ -n "$password" ]; then
cat <<EOF

Jenkins Login username:  admin
Jenkins Login password:  $password

EOF
fi

if ! "$cli" list-plugins | grep -q .; then
    echo "Restarting Jenkins to pick up plugins:"
    #"$cli" restart
    #when_ports_down 300 "$host" "$port"
    docker-compose -f "$config" restart jenkins-server "$@"

    when_jenkins_up
    SECONDS=0
    while [ "$SECONDS" -lt 300 ]; do
        if "$cli" list-plugins | grep -q .; then
            echo
            break
        fi
        tstamp "waiting for Jenkins to finish initializing and list plugins"
        sleep 1
    done
fi

echo "Validating Jenkinsfile"
"$cli" declarative-linter < "$Jenkinsfile"
echo

echo "Creating / Updating job - $job:"
if "$cli" list-jobs | grep -q "^$job$"; then
    echo "job already exists, updating..."
    "$cli" update-job "$job" < "$job_xml"
else
    echo "job does not exist, creating..."
    "$cli" create-job "$job" < "$job_xml"
fi
echo

echo "Enabling job - $job:"
"$cli" enable-job "$job"
echo

# -f waits for build
# -v prints build contents
echo "Building job - $job and tailing output:"
"$cli" build -f -v "$job"

#echo "Tailing last build:"
#"$cli" console "$job" -f
