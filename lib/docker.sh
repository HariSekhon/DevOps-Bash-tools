#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-02-07 22:42:47 +0000 (Sun, 07 Feb 2016)
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
srcdir_bash_tools_docker="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=1090,SC1091
. "$srcdir_bash_tools_docker/utils.sh"

docker_compose_quiet=""
if is_CI; then
    docker_compose_quiet="--quiet"
fi

is_docker_installed(){
    if type -P docker &>/dev/null; then
        return 0
    fi
    return 1
}

is_docker_available(){
    #[ -n "${TRAVIS:-}" ] && return 0
    if is_docker_installed; then
        if docker info &>/dev/null; then
            return 0
        fi
    fi
    #echo "Docker not available"
    return 1
}

is_docker_compose_available(){
    #[ -n "${TRAVIS:-}" ] && return 0
    if type -P docker-compose &>/dev/null; then
        return 0
    fi
    #echo "Docker Compose not available"
    return 1
}

check_docker_available(){
    if ! is_docker_installed; then
        echo 'WARNING: Docker not found, skipping checks!!!'
        exit 0
    fi
    if ! is_docker_available; then
        echo 'WARNING: Docker not available, skipping checks!!!'
        exit 0
    fi
    if ! is_docker_compose_available; then
        echo "WARNING: Docker Compose not found in \$PATH, skipping checks!!!"
        exit 0
    fi
    # alternative
    #export DOCKER_SERVICE="$(ps -o comm= $PPID)"
    export DOCKER_SERVICE="${BASH_SOURCE[1]#*test_}"
    export DOCKER_SERVICE="${DOCKER_SERVICE%.sh}"
    export DOCKER_CONTAINER="${COMPOSE_PROJECT_NAME:-docker}"
    # for Docker Machine but not Docker for Mac
    # nagios-plugins -> nagiosplugins
    export DOCKER_CONTAINER="${DOCKER_CONTAINER//-}"
    export DOCKER_CONTAINER="${DOCKER_CONTAINER}_${DOCKER_SERVICE}_1"
    # srcdir is defined in client scripts
    # shellcheck disable=SC2154
    export COMPOSE_FILE="$srcdir/docker/$DOCKER_SERVICE-docker-compose.yml"
}

is_docker_container_running(){
    local containers
    containers="$(docker ps)"
    if [ -n "${DEBUG:-}" ]; then
        echo "Containers Running:
$containers
"
    fi
    #if grep -q "[[:space:]]$1$" <<< "$containers"; then
    if [[ "$containers" =~ [[:space:]]$1$ ]]; then
        return 0
    fi
    return 1
}

is_inside_docker(){
    test -f /.dockerenv
}

# KUBERNETES_PORT=tcp://<ip_x.x.x.x>:443
# KUBERNETES_PORT_443_TCP=tcp://<ip_x.x.x.x>:443
# KUBERNETES_PORT_443_TCP_ADDR=<ip_x.x.x.x>
# KUBERNETES_PORT_443_TCP_PORT=443
# KUBERNETES_PORT_443_TCP_PROTO=tcp
# KUBERNETES_SERVICE_HOST=<ip_x.x.x.x>
# KUBERNETES_SERVICE_PORT=443
# KUBERNETES_SERVICE_PORT_HTTPS=443
is_inside_kubernetes(){
    [ -n "${KUBERNETES_PORT:-}" ]
}

declare_if_inside_docker(){
    if is_inside_docker; then
        echo
        echo "(running in Docker container $(hostname -f))"
        echo
    fi
}

docker_compose_pull(){
    if [ -z "${KEEPDOCKER:-}" ]; then
        if is_CI || [ -n "${DOCKER_PULL:-}" ]; then
            VERSION="${version:-}" docker-compose pull $docker_compose_quiet || :
        fi
    fi
}

docker_compose_path_version(){
    local path="$1"
    local dir_base="$2"
    if [ -z "${DOCKER_SERVICE:-}" ]; then
        echo "Error: \$DOCKER_SERVICE has not been set in environment yet, was check_docker_available() called first?"
        exit 1
    fi
    set +e
    local version
    version="$(docker-compose exec "$DOCKER_SERVICE" ls "$path" -1 --color=no |
                     grep --color=no -- "$dir_base.*[[:digit:]]" |
                     tr -d '\r' |
                     tee /dev/stderr |
                     tail -n 1 |
                     sed "s/$dir_base//"
                    )"
    set -e
    if [ -z "$version" ]; then
        echo "Error: failed to find docker compose path version from path $path for $dir_base!"
        exit 1
    fi
    echo "$version"
}

docker_compose_version_test(){
    local name="${1:-}"
    local version="${2:-}"
    if [ -z "$name" ]; then
        "ERROR: missing first arg for name to docker_compose_version_test()"
        exit 1
    fi
    if [ -z "$version" ]; then
        "ERROR: missing second arg for version to docker_compose_version_test()"
        exit 1
    fi
    if [ "$version" = "latest" ]; then
        echo "latest version, fetching latest version from DockerHub master branch"
        local version
        version="$(dockerhub_latest_version "$name")"
        echo "expecting version '$version'"
    fi
    hr
    found_version="$(docker_compose_path_version / "$name"-)"
    echo "found $name version $found_version"
    hr
    if [[ "$found_version" =~ $version ]]; then
        echo "$name docker version matches expected (found '$found_version', expected '$version')"
    else
        echo "Docker container version does not match expected version! (found '$found_version', expected '$version')"
        exit 1
    fi
}

docker_compose_port(){
    local env_var="${1:-}"
    local name="${2:-}"
    if [ -z "$env_var" ]; then
        echo "ERROR: docker_compose_port() first arg \$1 was not supplied for \$env_var"
        exit 1
    fi
    if [ -z "$name" ]; then
        name="$env_var"
    fi
    name="$name port"
    if ! [[ "$env_var" =~ .*_PORT$ ]]; then
        #env_var="$(tr '[[:lower:]]' '[[:upper:]]' <<< "$env_var")_PORT"
        # doesn't work on Mac
        #env_var="$(sed 's/.*/\U&/;s/[^[:alnum:]]/_/g' <<< "$env_var")_PORT"
        # shellcheck disable=SC2001
        env_var="$(sed 's/[^[:alnum:]]/_/g' <<< "$env_var" | tr '[:lower:]' '[:upper:]')_PORT"
    fi
    if [ -z "${DOCKER_SERVICE:-}" ]; then
        echo "ERROR: \$DOCKER_SERVICE is not set, cannot run docker_compose_port()"
        exit 1
    fi
    set +u
    if eval [ -z \$"${env_var}_DEFAULT" ]; then
        echo "ERROR: ${env_var}_DEFAULT is not set, cannot run docker_compose_port()"
        exit 1
    fi
    set -u
    # shellcheck disable=SC2006,SC2116
    eval printf "\"$name -> $`echo "${env_var}_DEFAULT"` => \""
    # shellcheck disable=SC2006,SC2116,SC2046
    export "$env_var"="$(eval docker-compose port "$DOCKER_SERVICE" $`echo "${env_var}_DEFAULT"` | sed 's/.*://')"
    if eval [ -z \$"$env_var" ]; then
        echo "ERROR: failed to get port mapping for $env_var"
        exit 1
    fi
    if eval [ -z \$"$env_var" ]; then
        echo "FAILED got no port mapping for $env_var... did the container crash?"
        exit 1
    fi
    if eval ! [[ \$"$env_var" =~ ^[[:digit:]]+$ ]]; then
        echo -n "ERROR: failed to get port mapping for $env_var - non-numeric port '"
        eval echo -n \$"$env_var"
        echo "' returned, possible parse error"
        exit 1
    fi
    eval echo "\$$env_var"
}

docker_exec(){
    if [ -n "${DOCKER_SKIP_EXEC:-}" ]; then
        echo "skipping docker exec: $*"
        return 0
    fi
    local user=""
    if [ -n "${DOCKER_USER:-}" ]; then
        user=" --user $DOCKER_USER"
    fi
    local MNTDIR="${DOCKER_MOUNT_DIR:-}"
    if [ -n "$MNTDIR" ]; then
        MNTDIR="$MNTDIR/"
    fi
    if [ -z "${DOCKER_JAVA_HOME:-}" ]; then
        # shellcheck disable=SC2086,SC2145
        run docker exec -i $user "$DOCKER_CONTAINER" "$MNTDIR""$@"
    else
        local cmds="export JAVA_HOME=$DOCKER_JAVA_HOME
$MNTDIR$*"
        echo  "docker exec -i$user \"$DOCKER_CONTAINER\" /bin/bash <<EOF
        $cmds
EOF"
        # use run rather than run++ and plain docker exec so that it inherits ERRCODE
        # shellcheck disable=SC2086
        run docker exec -i $user "$DOCKER_CONTAINER" /bin/bash <<EOF
        $cmds
EOF
    fi
}

docker_compose_exec(){
    local user=""
    if [ -n "${DOCKER_USER:-}" ]; then
        user=" --user $DOCKER_USER"
    fi
    local MNTDIR="${DOCKER_MOUNT_DIR:-}"
    if [ -n "$MNTDIR" ]; then
        MNTDIR="$MNTDIR/"
    fi
    if [ -z "${DOCKER_JAVA_HOME:-}" ]; then
        # shellcheck disable=SC2086
        run docker-compose exec $user "$DOCKER_SERVICE" "$MNTDIR$*"
    else
        local cmds="export JAVA_HOME=$DOCKER_JAVA_HOME
$MNTDIR$*"
        echo  "docker-compose exec$user \"$DOCKER_SERVICE\" /bin/bash <<EOF
        $cmds
EOF"
        # shellcheck disable=SC2086
        run docker-compose exec $user "$DOCKER_SERVICE" /bin/bash <<EOF
        $cmds
EOF
    fi
}

dockerhub_latest_version(){
    repo="${1-}"
    if [ -z "$repo" ]; then
        echo "Error: no repo passed to dockerhub_latest_version for first arg"
    fi
    set +e
    local version
    version="$(curl -sS "https://raw.githubusercontent.com/HariSekhon/Dockerfiles/master/$repo/Dockerfile" | awk -F= '/^ARG[[:space:]]+[A-Za-z0-9_]+_VERSION=/ {print $2; exit}')"
    set -e
    if [ -z "$version" ]; then
        version='.*'
    fi
    echo "$version"
}

docker_container_image(){
    local container_name="$1"
    docker ps --filter "name=^$container_name$" --format '{{.Image}}'
}

docker_container_exists(){
    local container_name="$1"
    docker ps -a --filter "name=^$container_name$" --format '{{.Status}}' | grep -q .
}

docker_container_exited(){
    local container_name="$1"
    docker ps -a --filter "name=^$container_name$" --format '{{.Status}}' | grep -Eqi 'Dead|Exited'
}

docker_container_not_running(){
    local container_name="$1"
    docker ps -a --filter "name=^$container_name$" --format '{{.Status}}' | grep -Eqi 'Created|Paused|Dead|Exited'
}

docker_pull(){
    local docker_image="$1"
    local version
    local opts
    if is_CI or ! is_interactive; then
        if [ "$(docker version --format '{{.Client.Version}}' | grep -o '[[:digit:]]*' | head -n 1)" -gt 18 ]; then
            opts="-q"
        else
            # Travis CI has Docker 18 without the -q / --quiet switch
            opts="> /dev/null"
        fi
    fi
    if [[ "$docker_image" =~ : ]]; then
        version="${docker_image#*:}"
        docker_image="${docker_image%:*}"
    else
        local version="$2"
    fi
    # don't pull if we already have the image locally - both to save time and remove internet dependency if running on a laptop
    if ! docker images --filter reference="$docker_image:$version" --format '{{.Repository}}:{{.Tag}}' | grep -q .; then
        # want splitting
        # shellcheck disable=SC2086
        eval docker pull ${opts:-} "$docker_image:$version"
    fi
}

external_docker(){
    [ -n "${EXTERNAL_DOCKER:-}" ] && return 0 || return 1
}

launch_container(){
    local image="${1:-${DOCKER_IMAGE}}"
    local container="${2:-${DOCKER_CONTAINER}}"
    local ports="${*:3}"
    if [ -n "${TRAP:-}" ] || is_CI; then
        trap_container "$container"
    fi
    if external_docker; then
        echo "External Docker detected, skipping container creation..."
        return 0
    else
        [ -n "${DOCKER_HOST:-}" ] && echo "using docker address '$DOCKER_HOST'"
        if ! is_docker_available; then
            echo "WARNING: Docker not found, cannot launch container $container"
            return 1
        fi
        # reuse container it's faster
        #docker rm -f -- "$container" &>/dev/null
        #sleep 1
        if [[ "$container" = *test* ]]; then
            docker rm -f -- "$container" &>/dev/null || :
        fi
        if ! is_docker_container_running "$container"; then
            # This is just to quiet down the CI logs from useless download clutter as docker pull/run doesn't have a quiet switch as of 2016 Q3
            if is_CI; then
                # pipe to cat tells docker that stdout is not a tty, switches to non-interactive mode with less output
                { docker pull "$image" || :; } | cat
            fi
            port_mappings=""
            for port in $ports; do
                port_mappings="$port_mappings -p $port:$port"
            done
            echo -n "starting container: "
            # need tty for sudo which Apache startup scripts use while SSH'ing localhost
            # eg. hadoop-start.sh, hbase-start.sh, mesos-start.sh, spark-start.sh, tachyon-start.sh, alluxio-start.sh
            # shellcheck disable=SC2086
            docker run -d -t --name "$container" ${DOCKER_OPTS:-} $port_mappings "$image" ${DOCKER_CMD:-}
            hr
            echo "Running containers:"
            docker ps
            hr
            #echo "waiting $startupwait seconds for container to fully initialize..."
            #sleep $startupwait
        else
            echo "Docker container '$container' already running"
        fi
    fi
    if [ -n "${ENTER:-}" ]; then
        docker exec -ti "$DOCKER_CONTAINER" bash
    fi
}

delete_container(){
    local container="${1:-$DOCKER_CONTAINER}"
    local msg="${2:-}"
    echo
    if [ -z "${NODELETE:-}" ] && ! external_docker; then
        if [ -n "$msg" ]; then
            echo "$msg"
        fi
        echo -n "Deleting container "
        docker rm -f -- "$container"
        untrap
    fi
}

trap_container(){
    local container="${1:-$DOCKER_CONTAINER}"
    # shellcheck disable=SC2154,SC2086
    trap 'result=$?; '"delete_container $container 'trapped exit, cleaning up container'"' || : ; exit $result' $TRAP_SIGNALS
}

docker_rmi_dangling_layers(){
    # want splitting
    # shellcheck disable=SC2046
    docker rmi $(docker images -q --filter dangling=true) 2>/dev/null || :
}

docker_rmi_grep(){
    docker images |
    grep -Ei -- "^$1" |
    awk '{print $1":"$2}' |
    xargs docker rmi --force || :
}

# to be called at end of scripts as well as trap function
docker_image_cleanup(){
    local docker_images
    if [ -n "${COMPOSE_FILE:-}" ] && [ -f "$COMPOSE_FILE" ]; then
        docker_images="$(grep '^[[:space:]]*image' "$COMPOSE_FILE" | sed 's/.*image:[[:space:]]*//; s/:.*//')"
    fi
    if [ -n "${docker_images:-}" ]; then
        for docker_image in $docker_images; do
            docker_rmi_grep "$docker_image" || :
        done
    fi
    docker_rmi_dangling_layers
}
