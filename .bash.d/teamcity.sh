#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-24 17:09:11 +0000 (Tue, 24 Nov 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# finds and loads the current superuser token from the local docker compose to the environment for immediate use with teamcity_api.sh
teamcity_superuser_token(){
    TEAMCITY_SUPERUSER_TOKEN="$(
        docker-compose -f "$(dirname "${BASH_SOURCE[0]}")/../setup/teamcity-docker-compose.yml" \
            logs teamcity-server | \
        grep -E -o 'Super user authentication token: [[:alnum:]]+' | \
        tail -n1 | \
        awk '{print $5}' || :
    )"

    export TEAMCITY_SUPERUSER_TOKEN
}
