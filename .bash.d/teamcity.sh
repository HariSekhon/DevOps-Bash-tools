#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-24 17:09:11 +0000 (Tue, 24 Nov 2020)
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
#                                T e a m C i t y
# ============================================================================ #

# sets TeamCity URL to the local docker and finds and loads the current container's superuser token to the environment for immediate use with teamcity_api.sh
teamcity_local(){
    TEAMCITY_SUPERUSER_TOKEN="$(
        # project name must match COMPOSE_PROJECT_NAME from teamcit.sh otherwise will fail to find token
        docker-compose -p bash-tools -f "$(dirname "${BASH_SOURCE[0]}")/../docker-compose/teamcity.yml" \
            logs teamcity-server | \
        grep -E -o 'Super user authentication token: [[:alnum:]]+' | \
        tail -n1 | \
        awk '{print $5}' || :
    )"

    export TEAMCITY_SUPERUSER_TOKEN
    export TEAMCITY_URL="http://localhost:8111"
}
