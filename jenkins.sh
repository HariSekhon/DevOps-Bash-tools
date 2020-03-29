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

server="http://localhost:8080"
#api="$server/go/api"
cli="$srcdir/jenkins_cli.sh"

repo="${srcdir##*/}"
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

#git_repo="$(git remote -v | grep github.com | sed 's/.*github.com/https:\/\/github.com/; s/ .*//')"
#repo="${git_repo##*/}"

opts=""
if [ "$action" = up ]; then
    opts="-d"
fi

echo "Booting Jenkins docker:"
docker-compose -f "$config" "$action" $opts "$@"
echo

when_url_content "$server" '(?i:jenkins|hudson)'
echo

echo "Installing plugins"
docker-compose -f "$config" exec -T jenkins-server /usr/local/bin/install-plugins.sh < "$plugins_txt"
echo

password="$("$srcdir/jenkins_password.sh" || :)"

if [ -n "$password" ]; then
cat <<EOF

Jenkins Login username:  admin
Jenkins Login password:  $password

EOF
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

# -f waits for build
# -v prints build contents
echo "Building job - $job and tailing output:"
"$cli" build -f -v "$job"

#echo "Tailing last build:"
#"$cli" console "$job" -f
