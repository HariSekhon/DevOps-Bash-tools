#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-22 17:18:09 +0000 (Mon, 22 Feb 2021)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                                 J e n k i n s
# ============================================================================ #

#alias jenkins_cli='java -jar ~/jenkins-cli.jar -s http://jenkins:8080'
alias jenkins-cli='jenkins_cli.sh'

#alias backup_jenkins="rsync -av root@jenkins:/jenkins_backup/*.zip '~/jenkins_backup/'"

# sets Jenkins URL to the local docker and finds and loads the current container's superuser token to the environment for immediate use with jenkins_api.sh
jenkins_local(){
    JENKINS_SUPERUSER_PASSWORD="$(
        docker-compose -p bash-tools -f "$(dirname "${BASH_SOURCE[0]}")/../docker-compose/jenkins.yml" \
            exec -T jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword </dev/null
            # use terminal or gets carriage return and would have to tr -d '\r'
    )"

    export JENKINS_USER=admin
    export JENKINS_PASSWORD="$JENKINS_SUPERUSER_PASSWORD"
    export JENKINS_TOKEN="$JENKINS_PASSWORD"
    export JENKINS_API_TOKEN="$JENKINS_PASSWORD"
    export JENKINS_USER_ID="$JENKINS_USER"
    export JENKINS_URL="http://localhost:8080"
}

alias jenkinspass="jenkins_password.sh | copy_to_clipboard"
