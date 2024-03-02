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

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# dipping into interactive library for opening browser to TeamCity to accept EULA
# XXX: order is important here because there is an interactive library of retry() and a scripting library version of retry() and we want the latter, which must be imported second
# shellcheck disable=SC1090,SC1091
. "$srcdir/.bash.d/network.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034
usage_description="
Boots TeamCity CI cluster with server and agent(s) in Docker, and builds the current repo

- boots TeamCity server and agent in Docker
- authorizes the agent(s) to begin building
- waits for you to accept the EULA
  - prints the TeamCity URL
  - opens the TeamCity web UI

- creates an administator-level user (\$TEAMCITY_USER, / \$TEAMCITY_PASSWORD - defaults to admin / admin)
  - sets the full name, email, and VCS commit username to Git's user.name and user.email if configured for TeamCity to Git VCS tracking integration
  - opens the TeamCity web UI login page in browser

- creates a GitHub OAuth connection if credentials are available (\$TEAMCITY_GITHUB_CLIENT_ID and \$TEAMCITY_GITHUB_CLIENT_SECRET)
  - this saves you having to use your own username and password for the GitHub VCS such as the config repo - just click the GitHub icon next to the VCS url to auto-authenticate

- if there is a .teamcity.vcs.json VCS configuration in the current directory, creates the VCS to use as a config sync repo
  - if this is a private repo, you either need to put the credentials in the file temporarily, or set the password to blank, and edit it after boot
    - currently must use authentication even if th repo is public:  https://youtrack.jetbrains.com/issue/TW-69183
  - if GitHub OAuth connection credentials are available, will instead look for .teamcity.auth.vcs.json
  - you'll need to disable & re-enable the project's Versioned Settings to get the import dialog for your projects before it starts sync'ing
    - this is another TeamCity limitation:  https://youtrack.jetbrains.com/issue/TW-58754

Usage:

    ${0##*/} [up]

    ${0##*/} down

    ${0##*/} ui     - prints the TeamCity Server URL and automatically opens in browser


Idempotent, you can re-run this and continue from any stage


The official docker images from JetBrains are huge so the first pull may take a while


See Also:

    teamcity_api.sh - makes heavy use of this script to handle setup API calls with authentication


Advanced:

TeamCity GitHub OAuth integration - set up your TeamCity OAuth credentials here:

    https://github.com/settings/developers

If \$TEAMCITY_GITHUB_CLIENT_ID and \$TEAMCITY_GITHUB_CLIENT_SECRET are available in the environment it will configure a connection for your GitHub VCS roots authentication


If your GitHub OAuth connection has been created you can use this to authenticate the TeamCity VCS root in the Root project,
and use that to sync your Project configuration to/from Github under Project's Settings -> Versioned Settings using the VCS referenced from the Root project.

It's better to keep the TeamCity config VCS in the Root project because when you sync a project and it replaces the VCS json credential it breaks the GitHub sync
and needs to be re-created. By putting it in the Root project and only enabling VCS sync on the sub-project you avoid this problem.


Tested on TeamCity 2020.1, 2020.2
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[ up | down | ui ]"

help_usage "$@"

export COMPOSE_PROJECT_NAME="bash-tools"
export COMPOSE_FILE="$srcdir/../docker-compose/teamcity.yml"

vcs_config=".teamcity.vcs.json"
# OAuth connection
vcs_config_auth=".teamcity.vcs.oauth.json"
# SSH key connection
vcs_config_ssh_auth=".teamcity.vcs.ssh.json"

TEAMCITY_SSH_KEY="${TEAMCITY_SSH_KEY:-$HOME/.ssh/id_rsa}"

project="GitHub"

#teamcity_port="$(docker-compose config | sed -n '/teamcity-server:[[:space:]]*$/,$p' | awk '/- published: [[:digit:]]+/{print $3; exit}')"

# don't take any change this script could run against a real teamcity server for safety
#export TEAMCITY_URL="http://${TEAMCITY_HOST:-localhost}:${TEAMCITY_PORT:-8111}"
export TEAMCITY_URL="http://${DOCKER_HOST:-localhost}:8111"

if ! type docker-compose &>/dev/null; then
    "$srcdir/../install/install_docker_compose.sh"
fi

action="${1:-up}"
shift || :

if [ "$action" = up ]; then
    timestamp "Booting TeamCity cluster:"
    # starting agents later they won't be connected in time to become authorized
    # only start the server, don't wait for the agent to download before triggering the URL to prompt user for initialization so it can progress while agent is downloading
    #docker-compose up -d teamcity-server "$@"
    docker-compose up -d "$@"
    echo
elif [ "$action" = restart ]; then
    docker-compose down
    echo
    exec "${BASH_SOURCE[0]}" up
elif [ "$action" = ui ]; then
    echo "TeamCity Server URL:  $TEAMCITY_URL"
    open "$TEAMCITY_URL"
    exit 0
else
    docker-compose "$action" "$@"
    echo
    exit 0
fi

# fails due to 302 redirect to http://localhost:8111/setupAdmin.html
# / and /setupAdmin.html and /login.html
#when_url_content "$TEAMCITY_URL/login.html" '(?i:teamcity)'
#when_ports_available 60 "${TEAMCITY_HOST:-localhost}" "${TEAMCITY_PORT:-8111}"
when_url_content 60 "$TEAMCITY_URL" '.*'
echo

# XXX: database.properties is mounted to skip the database step now
is_setup_in_progress(){
     # don't let cut off output affect the return code
     { curl -sSL "$TEAMCITY_URL" || : ; } | \
       grep -qi -e 'first.*start' \
                -e 'database.*setup' \
                -e 'TeamCity Maintenance' \
                -e 'Setting up'
}

timestamp "TeamCity Server URL:  $TEAMCITY_URL"
echo
if is_setup_in_progress; then
    timestamp "Opening TeamCity Server URL in web browser to continue, click proceed, accept EULA etc.."
    echo
    open "$TEAMCITY_URL"
fi

# too late, agent won't arrive in the unauthorized list in time to be found and authorized before this script exits, agents must boot in parallel with server not later
# now download and start the agent(s) while the server is booting
#docker-compose up -d

# now continue configuring server

max_secs=300

SECONDS=0
timestamp "waiting for up to $max_secs seconds for user to click proceed through First Start and database setup pages"
while is_setup_in_progress; do
    timestamp "waiting for you to click proceed through First Start & setup pages and then preliminary initialization to finish"
    if [ $SECONDS -gt $max_secs ]; then
        die "Did not progress past First Start and setup pages within $max_secs seconds"
    fi
    sleep 3
done
echo

# second run would break here as this wouldn't come again, must use .* search
# just to check we are not getting a temporary 404 or something that happens before the EULA comes up
#when_url_content 60 "$TEAMCITY_URL" "license.*agreement"
when_url_content 60 "$TEAMCITY_URL" ".*"
echo

SECONDS=0
timestamp "waiting for up to $max_secs seconds for user to accept EULA"
# curl gives an error when grep cuts its long EULA agreement short:
# (23) Failed writing body
while { curl -sSL "$TEAMCITY_URL" 2>/dev/null || : ; } |
      grep -qi 'license.*agreement'; do
    timestamp "waiting for you to accept the license agreement"
    if [ $SECONDS -gt $max_secs ]; then
        die "Did not accept EULA within $max_secs seconds"
    fi
    sleep 3
done
echo

SECONDS=0
timestamp "waiting for up to $max_secs seconds for TeamCity to finish initializing"
# too transitory to be idempotent
#while ! curl -sS "$TEAMCITY_URL" | grep -q 'TeamCity is starting'; do
# although hard to miss this log as not a fast scroll, might break idempotence for re-running later if logs are cycled out of buffer
#while ! docker-compose logs --tail 50 teamcity-server | grep -q 'TeamCity initialized'; do
while ! { docker-compose logs teamcity-server || : ; } |
      grep -q -e 'Super user authentication token'; do
              #-e 'TeamCity initialized' # happens just before but checking for the super user token achieves both and protects against race condition
    timestamp 'waiting for TeamCity server to finish initializing and reveal superuser token in logs'
    if [ $SECONDS -gt $max_secs ]; then
        die "TeamCity server failed to initialize within $max_secs seconds (perhaps you didn't trigger the UI to continue initialization?)"
    fi
    sleep 3
done
echo

TEAMCITY_SUPERUSER_TOKEN="$(docker-compose logs teamcity-server | grep -E -o 'Super user authentication token: [[:alnum:]]+' | tail -n1 | awk '{print $5}' || :)"

if [ -z "$TEAMCITY_SUPERUSER_TOKEN" ]; then
    timestamp "ERROR: Super user token not found in docker logs (maybe premature or late ie. logs were already cycled out of buffer?)"
    exit 1
fi

export TEAMCITY_SUPERUSER_TOKEN

timestamp "TeamCity superuser token: $TEAMCITY_SUPERUSER_TOKEN"
timestamp "(this must be used with a blank username via basic auth if using the API)"
echo

teamcity_user="${TEAMCITY_USER:-admin}"
teamcity_password="${TEAMCITY_PASSWORD:-admin}"

user_already_exists=0
api_token=""
#timestamp "Checking if teamcity user '$teamcity_user' exists"
timestamp "Checking if any user already exists"
users="$("$srcdir/teamcity_api.sh" /users -sSL --fail | jq -r '.user[].username')"
#if grep -Fxq "$teamcity_user" <<< "$users"; then
#    timestamp "teamcity user '$teamcity_user' user already detected, skipping creation"
if [ -n "${users//[[:space:]]/}" ]; then
    timestamp "users already exist, not creating teamcity administrative user '$teamcity_user'"
    user_already_exists=1
else
    #timestamp "Creating teamcity user '$teamcity_user':"
    timestamp "no users exist yet, creating teamcity user '$teamcity_user'"
    "$srcdir/teamcity_api.sh" /users -sSL --fail \
         -d "{ \"username\": \"$teamcity_user\", \"password\": \"$teamcity_password\"}"
         # Note: Unnecessary use of -X or --request, POST is already inferred.
         #-X POST \
    # no newline returned if error eg.
    #       Details: jetbrains.buildServer.server.rest.errors.BadRequestException: Cannot create user as user with the same username already exists, caused by: jetbrains.buildServer.users.DuplicateUserAccountException: The specified username 'admin' is already in use by some other user.
    #       Invalid request. Please check the request URL and data are correct.
    echo
    echo
    git_user="$(git config user.name)"
    git_email="$(git config user.email)"
    if [ -n "$git_user" ]; then
        timestamp "Setting teamcity user $teamcity_user's username to '$git_user'"
        "$srcdir/teamcity_api.sh" "/users/$teamcity_user/name" -X PUT -d "$git_user" -H 'Content-Type: text/plain'  -H 'Accept: text/plain'
        # API echo's username without newline
        echo
        timestamp "Setting teamcity user $teamcity_user's VCS default username to '$git_user'"
        "$srcdir/teamcity_api.sh" "/users/admin/properties/plugin:vcs:anyVcs:anyVcsRoot" -X PUT -d "$git_user" -H 'Content-Type: text/plain'  -H 'Accept: text/plain'
        # API echo's username without newline
        echo
    fi
    if [ -n "$git_email" ]; then
        timestamp "Setting teamcity user $teamcity_user's email to '$git_email'"
        "$srcdir/teamcity_api.sh" "/users/$teamcity_user/email" -X PUT -d "$git_email" -H 'Content-Type: text/plain'  -H 'Accept: text/plain'
        # prints email without newline
        echo
    fi
    timestamp "Setting teamcity user '$teamcity_user' as system administrator:"
    "$srcdir/teamcity_api.sh" "/users/username:$teamcity_user/roles/SYSTEM_ADMIN/g/" -sSL --fail -X PUT > /dev/null
    # no newline returned
    echo
    api_token="$("$srcdir/teamcity_api.sh" "/users/$teamcity_user/tokens" -sSL | \
                 jq -r '.token[]' || :)"
    # XXX: could create expiring self-deleting token here each time, but would make idempotence tricker
    # due to timings and also use might want to use it in teamcity_api.sh later
    if [ -n "$api_token" ]; then
        timestamp "TeamCity user '$teamcity_user' already has an API token, skipping token creation"
        timestamp "since we cannot get existing token value out of the API, will load TEAMCITY_SUPERUSER_TOKEN to environment to use instead"
    else
        timestamp "Creating API token for user '$teamcity_user'"
        api_token="$("$srcdir/teamcity_api.sh" "/users/$teamcity_user/tokens/mytoken" -sSL --fail -X POST | jq -r '.value')"
        timestamp "here is your user API token, export this and then you can easily use teamcity_api.sh:"
        echo
        # this takes precedence so disable it and use the user's api token instead
        unset TEAMCITY_SUPERUSER_TOKEN
        echo "export TEAMCITY_URL=$TEAMCITY_URL"
        export TEAMCITY_URL="$TEAMCITY_URL"
        echo "export TEAMCITY_TOKEN=$api_token"
        export TEAMCITY_TOKEN="$api_token"
    fi
fi
echo

if [ "$user_already_exists" = 0 ]; then
    timestamp "Login here with username '$teamcity_user' and password: \$TEAMCITY_PASSWORD (default: admin):"
    echo
    login_url="$TEAMCITY_URL/login.html"
    echo "$login_url"
    echo
    timestamp "Ppening TeamCity Server URL"
    open "$login_url"
    echo
    echo
fi

timestamp "getting list of expected agents"
expected_agents="$(docker-compose config | awk '/^[[:space:]]+AGENT_NAME:/ {print $2}' | sed '/^[[:space:]]*$/d')"
num_expected_agents="$(grep -c . <<< "$expected_agents" || :)"

get_connected_agents(){
    "$srcdir/teamcity_api.sh" "/agents?locator=connected:true,authorized:any" -sSL --fail |
    jq -r '.agent[].name'
}

SECONDS=0
timestamp "waiting for $num_expected_agents expected agent(s) to connect before authorizing them"
while true; do
    num_connected_agents="$(get_connected_agents | grep -c . || :)"
    timestamp "connected agents: $num_connected_agents"
    if [ "$num_connected_agents" -ge "$num_expected_agents" ]; then
        timestamp "$num_connected_agents connected agents >= $num_expected_agents expected agents, continuing"
        break
    fi
    if [ $SECONDS -gt $max_secs ]; then
        timestamp "giving up waiting for connect agents after $max_secs"
        break
    fi
    sleep 3
done
echo

timestamp "getting list of unauthorized agents"
# using our new teamcity API token, let's agents waiting to be authorized
unauthorized_agents="$("$srcdir/teamcity_api.sh" "/agents?locator=authorized:false" -sSL --fail | jq -r '.agent[].name')"

timestamp "authorizing any expected agents that are not currently authorized"
if [ -z "$unauthorized_agents" ]; then
    timestamp "no unauthorized agents found"
fi
for agent in $unauthorized_agents; do
    # XXX: recreated agents end up with a digit appended to the name to avoid clash with old stale agent reference
    #      if the agent disk state isn't lost this shouldn't be needed, but this environment is disposable so allow this
    #      this is only a local environment so we don't have to worry about rogue agents
    for expected_agent in $expected_agents; do
        # grep -f would be easier but don't want to depend on have the GNU version installed and then remapped via func
        if [[ "$agent" =~ ^$expected_agent(-[[:digit:]]+)?$ ]]; then
            timestamp "authorizing expected agent '$agent'"
            # needs -H 'Accept: text/plain' to override the default -H 'Accept: application/json' from teamcity_api.sh
            # otherwise gets 403 error and then even switching to -H 'Accept: text/plain' still breaks due to cookie jar behaviour,
            # so teamcity_api.sh now uses a unique cookie jar per script run and clears the cookie jar first
            "$srcdir/teamcity_api.sh" "/agents/$agent/authorized" -X PUT -d true -H 'Accept: text/plain' -H 'Content-Type: text/plain'
            # no newline returned
            echo
            continue 2
        fi
    done
    timestamp "WARNING: unauthorized agent '$agent' was not expected, not automatically authorizing"
done
echo

# this stops us accumulating huge numbers of agent-[[:digit:]] increments each time
timestamp "deleting old disconnected agent references"
# slight race condition here but it's not critical
disconnected_agents="$("$srcdir/teamcity_api.sh" "/agents?locator=connected:false" -sSL --fail | jq -r '.agent[].name')"
for disconnected_agent in $disconnected_agents; do
    timestamp "deleting disconnected agent '$disconnected_agent'"
    "$srcdir/teamcity_api.sh" "/agents/$disconnected_agent" -X DELETE
done
echo

if [ -f "$TEAMCITY_SSH_KEY" ]; then
    # overwrites key if already exists
    if "$srcdir/teamcity_upload_ssh_key.sh" "$TEAMCITY_SSH_KEY" "VCS SSH Key"; then
        if [ -f "$vcs_config_ssh_auth" ]; then
            echo
            timestamp "switching VCS config to '$vcs_config_ssh_auth'"
            vcs_config="$vcs_config_ssh_auth"
        fi
    fi
    echo
fi

if [ -n "${TEAMCITY_GITHUB_CLIENT_ID:-}" ] && [ -n "${TEAMCITY_GITHUB_CLIENT_SECRET:-}" ]; then
    # detects and skips creation if an OAuth connection named 'GitHub.com' already exists
    "$srcdir/teamcity_create_github_oauth_connection.sh"
    echo
    if [ "$vcs_config" != "$vcs_config_ssh_auth" ]; then
        if [ -f "$vcs_config_auth" ]; then
            timestamp "switching VCS config to '$vcs_config_auth'"
            vcs_config="$vcs_config_auth"
            echo
        fi
    fi
fi

if [ -f "$vcs_config" ]; then
    #timestamp "Now creating primary project '$project'"
    # XXX: TeamCity API doesn't yet support creating a project from a saved configuration via the API, see this ticket:
    #
    #      https://youtrack.jetbrains.com/issue/TW-43542
    #
    # So we create an empty project, then configure a VCS root to GitHub and reconfigure the project to pull from a GitHub repo
    # TODO: get the project name from the config file
    "$srcdir/teamcity_create_project.sh" "$project"
    echo
    vcs_id="$(jq -r .id < "$vcs_config")"
    project_id="$(jq -r .project.id < "$vcs_config")"
    if "$srcdir/teamcity_vcs_roots.sh" | grep -qi "^${vcs_id}[[:space:]]"; then
        timestamp "VCS root '$vcs_id' already exists, skipping creation"
    else
        if [ "$project_id" != "_Root" ]; then
            timestamp "Creating VCS container project '$project_id' if not already exists..."
            "$srcdir/teamcity_create_project.sh" "$project_id"
        fi
        # XXX: this fails when TeamCity has only just booted, probably due to some initialization timing, but works on second run, so just wait for it to succeed
        # UPDATE: seems this errors the first time yet still creates it and the second try skips as already exists
        retry 300 "$srcdir/teamcity_create_vcs_root.sh" "$vcs_config"
    fi
    echo
    timestamp "Configuring project Versioned Settings to import all buildTypes and VCS"
    "$srcdir/teamcity_project_set_versioned_settings.sh" "$project"
    echo
    echo
    timestamp "NOTICE: you need to enable VCS authentication for write access to be able to sync project configs:"
    timestamp "        (even if you have GitHub OAuth connection automated, you still need to click on the GitHub icon to initialize the sign-in)"
    echo
    printf '\t%s\n' "$TEAMCITY_URL/admin/editVcsRoot.html?action=editVcsRoot&vcsRootId=$vcs_id"
    echo
    echo
    timestamp "This is a limitation of the TeamCity API (as of Dec 2020), documented here:"
    echo
    printf '\t%s\n' "https://youtrack.jetbrains.com/issue/TW-69183"
    echo
    echo
    timestamp "NOTICE: one you've enabled authenticated access to the VCS root you'll have to disable and re-enable the '$project' project's Versioned Settings to get the import dialog for config sync to start working"
    echo
    printf '\t%s\n' "$TEAMCITY_URL/admin/editProject.html?projectId=$project&tab=versionedSettings"
    echo
    echo
    timestamp "This is a limitation of the TeamCity API (as of Dec 2020), documented here:"
    echo
    printf '\t%s\n' "https://youtrack.jetbrains.com/issue/TW-58754"
    echo
    echo
else
    timestamp "no config found: $vcs_config - skipping VCS setup and versioning integration / import"
fi
echo

#timestamp "Optimistically setting any buildTypes descriptions from their GitHub repos (ignoring failures)"
#"$srcdir/teamcity_buildtypes_set_description_from_github.sh" || :

timestamp "Build status icons:"
echo
printf '\t%s\n' "$TEAMCITY_URL/app/rest/builds/<build>/statusIcon.svg"
echo
timestamp "(requires this setting for each buildType:  General Settings -> 'enable status widget'  to permit unauthenticated status badge access)"
echo
echo
timestamp "TeamCity is up and ready"
