#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-11-05 20:53:32 +0000
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# ============================================================================ #
#                                  D o c k e r
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# shellcheck disable=SC1090,SC1091
[ -f ~/.docker_vars ] && . ~/.docker_vars

#if is_linux && type -P podman &>/dev/null; then
#    alias docker="podman"
#fi

export DOCKER_BUILDKIT=1

# for new M1 Macs which otherwise fail to build with errors like this:
#
#   AWS CLI version: qemu-x86_64: Could not open '/lib64/ld-linux-x86-64.so.2': No such file or directory
#
export DOCKER_DEFAULT_PLATFORM=linux/amd64

alias dh=hub-tool
alias dc=docker-compose
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dst="dockerhub_show_tags.py"
# -l shows latest container, -q shows only ID
alias dl='docker ps -lq'
alias dockerimg='$EDITOR "$bash_tools/setup/docker-images.txt"'

# wipe out exited containers
alias dockerrm='docker rm -- $(docker ps -qf status=exited)'

alias dockerr=dockerrunrm
alias dock=dockerr
alias dockere=dockerexec
alias de=dockere

alias dockerrma=dockerrmall

# wipe out dangling image layers
#alias dockerrmi='docker rmi $(docker images -q --filter dangling=true)'
dockerrmi(){
    # want word splitting here
    # shellcheck disable=SC2046
    docker rmi $(docker images -q --filter dangling=true)
}

# docker-compose -f ...
dcf(){
    local docker_compose_yaml="$1"
    if ! [ -f "$docker_compose_yaml" ] &&
         [ -f "docker-compose.yaml" ]; then
        docker_compose_yaml=docker-compose.yaml
    fi
    shift
    docker-compose -f "$docker_compose_yaml" up "$@"
    docker-compose -f "$docker_compose_yaml" logs -f
}

# starts the docker VM, shows ASCII whale, but slow
#alias dockershell="/Applications/Docker/Docker\ Quickstart\ Terminal.app/Contents/Resources/Scripts/start.sh"
# better
#alias dockervm="VBoxManage controlvm startvm default"
#alias dockervm="docker-machine start default"

#alias dm="docker-machine"
#alias dockerrr="docker-machine restart default"
#alias dockerreload="docker-machine env default > '$bash_tools/.docker_vars'; . '$bash_tools/.docker_vars'"

#dockerstart(){
#    if ! docker-machine status default | grep -q Running; then
#        docker-machine start default
#        sleep 20
#    fi
#    docker start $(cat "$bash_tools/docker-start.txt")
#}

# avoid external commands per shell, slows down new shells and wastes battery
# switched to using ~/.docker_vars file which is cheaper due to less forks and picked up in each new shell
#if type -P docker-machine &>/dev/null; then
#    if docker-machine status default | grep -q -e Started -e Running; then
#        eval $(docker-machine env default)
#    fi
#fi

#alias dockerr="docker run --rm -ti"
function dockerrunrm(){
    local args=()
    local passed_first_non_switch_arg=0  # when this latch gets to level 3 we stop doing prefix processing to not adulterate ls -l / type args
    for x in "$@"; do
        if [ $passed_first_non_switch_arg -lt 3 ]; then
            if [ "${x:0:1}" = "-" ]; then
                passed_first_non_switch_arg=1
            elif [ $passed_first_non_switch_arg -eq 1 ]; then
                passed_first_non_switch_arg=2
            elif [ $passed_first_non_switch_arg -lt 3 ]; then
                if [ "${x:0:1}" = "/" ]; then
                    if [[ "$x" != */Users/* && "$x" != */home/* ]] &&
                       [ "$(strLastIndexOf "$x" / )" -eq 1 ]; then
                        x="harisekhon$x"
                    fi
                fi
                passed_first_non_switch_arg=3
            else
                ((passed_first_non_switch_arg+=1))
            fi
        fi
        args+=("$x")
    done
    # Alpine 2 is dead in the water since the package list repos don't even load any more:
    #
    # # apk update
    # fetch http://dl-4.alpinelinux.org/alpine/v2.7/main/x86_64/APKINDEX.tar.gz
    # wget: server returned error: HTTP/1.1 404 Not Found
    # ERROR: http://dl-4.alpinelinux.org/alpine/v2.7/main: Bad address
    # WARNING: Ignoring APKINDEX.0f59c441.tar.gz: No such file or directory
    #
    #if [[ "$args" =~ alpine:2 ]] && ! [[ "$args" =~ [[:space:]] ]]; then
    #    echo "warning: using alpine:2.* with args but alpine:2.* doesn't have a default CMD so adding 'sh' arg" >&2
    #    args="$args sh"
    #fi
    # want arg splitting
    docker run --rm -ti -v "$PWD":/pwd -w /pwd "${args[@]}"
}
alias drun='docker run --rm -ti -v "${PWD}":/app'

docker_get_container_ids(){
    local exclude_file=~/docker-perm.txt
    local args=()
    # if exclude file doesn't exist, grep fails entirely and we get no IDs returned, even pre-emptively replacing with /dev/null doesn't work, so omit the option entirely
    if [ -f "$exclude_file" ]; then
        args=(-f "$exclude_file")
    fi
    docker ps -a --format "{{.ID}} {{.Names}}" |
    if [ ${#args} -gt 0 ]; then
        grep -vi "${args[@]}" 2>/dev/null
    else
        cat
    fi |
    awk '{print $1}'
}

dockerrmall(){
    # would use xargs -r / --no-run-if-empty but that is GNU only, doesn't work on Mac
    local ids=()
    read -r -a ids <<< "$(docker_get_container_ids)"
    if [ ${#ids} -gt 0 ]; then
        docker rm -f -- "${ids[@]}"
    fi
}

dockerrmigrep(){
    for x in "$@"; do
        docker images |
        grep "$x" |
        grep -v "<none>" |
        awk '{print $1":"$2}' |
        xargs -r docker rmi --
    done
}

dockerrmgrep(){
    for x in "$@"; do
        docker ps -a |
        grep "$x" |
        awk '{print $NF}' |
        xargs -r docker rm -f --
    done
}

dockerip(){
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
}

# this goes to the last created and sometimes exited container
#alias dockere='docker exec -ti $(docker ps -lq) /bin/bash'
dockerexec(){
    if [ $# -gt 0 ]; then
        container="$(docker ps | grep -i "$1" | awk '{print $1}' | head -n1)"
    else
        container="$(docker ps -q | head -n1)"
    fi
    docker exec -ti "$container" /bin/sh
}

docker_get_images(){
    # uniq_order_preserved.pl is in the DevOps-Perl-tools repo on github and should be in the $PATH
    # too many images on dockerhub to pull, fills up filesystem
    #echo "$(dockerhub_search.py harisekhon -n 1000 | tail -n +2 | awk '{print $1}' | sort) $(sed 's/#.*//;/^[[:space:]]*$/d' "$bash_tools/setup/docker-images.txt" | uniq_order_preserved.pl)"
    sed 's/#.*//;/^[[:space:]]*$/d' "$bash_tools/setup/docker-images.txt" |
    uniq_order_preserved.pl
}

dockerpull1(){
    # pull only latest tag, mine first, then official
    local images="${*:-}"
    [ -z "$images" ] && images="$(docker_get_images)"
    images="$(grep -v ":" <<< "$images")"
    whendone "docker pull" # must be first arg so quoted, [l] trick not needed as grep -v grep's
    for image in $images; do
        #whendone "docker pull" # must be first arg so quoted, [l] trick not needed as grep -v grep's
        timestamp "docker pull $image"
        #docker pull "$image" | cat &
        docker pull "$image"
        # wipe out dangling image layers
        dockerrmi
        echo
    done
}
dockerpullgithub(){
    dockerpull1 harisekhon/{nagios-plugins,pytools,tools,centos-github,debian-github,ubuntu-github,alpine-github}
}

dockerpull(){
    local images="${*:-}"
    [ -z "$images" ] && images="$(docker_get_images)"
    dockerpull1 "$images"
    images="$(grep -i -e harisekhon -e ":" <<< "$images")"
    #local images="$(grep -i -e ":" <<< "$images")"
    # now pull all tags, mine first, then official
    whendone "docker pull" # must be first arg so quoted, [l] trick not needed as grep -v grep's
    for image in $images; do
        #whendone "docker pull" # must be first arg so quoted, [l] trick not needed as grep -v grep's
        if [[ "$image" = harisekhon/* && ! "$image" =~ ":" ]]; then
            [[ "$image" =~ presto.*-dev ]] && continue
            for tag in $(dockerhub_show_tags.py -q "$image" | grep -v '^latest$'); do
                timestamp "docker pull $image:$tag"
                #docker pull "$image":"$tag" | cat &
                docker pull "$image":"$tag"
                echo
            done
        else
            timestamp docker pull "$image"
            #docker pull "$image" | cat &
            docker pull "$image"
            echo
        fi
        # wipe out dangling image layers
        dockerrmi
    done
}

dockerpull1r(){
    while true; do
        dockerpull1 "$@"
        wait
        echo -e '\n\nsleeping for 1 hour\n\n'
        sleep 3600
    done
}

dockerpullr(){
    while true; do
        dockerpull "$@"
        wait
        echo -e '\n\nsleeping for 1 hour\n\n'
        sleep 3600
    done
}

# quick, only pull things for which we don't already have local images
dockerpullq(){
    for x in $(docker_get_images); do
        docker images | grep -q "^${x}[[:space:]]" && continue
        whendone "docker pull" # must be first arg so quoted, [l] trick not needed as grep -v grep's
        timestamp docker pull "$x"
        docker pull "$x"
    done
    # wipe out dangling image layers
    dockerrmi
}
