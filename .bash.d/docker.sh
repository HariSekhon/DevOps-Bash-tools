#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-11-05 20:53:32 +0000
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                                  D o c k e r
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
. "$bash_tools/.bash.d/os_detection.sh"

# shellcheck disable=SC1090
[ -f ~/.docker_vars ] && . ~/.docker_vars

#if [ -n "$LINUX" ] && type podman &>/dev/null; then
#    alias docker="podman"
#fi

alias dps='docker ps'
alias dpsa='docker ps -a'
alias dst="dockerhub_show_tags.py"
# -l shows latest container, -q shows only ID
alias dl='docker ps -lq'
alias dockerimg='$EDITOR ~/docker-images.txt'

# wipe out exited containers
alias dockerrm='docker rm $(docker ps -qf status=exited)'

alias dockerr=dockerrunrm
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
    local args=""
    for x in "$@"; do
        if [ "${x:0:1}" = "/" ]; then
            if [[ "$x" != */Users/* && "$x" != */home/* ]] &&
               [ "$(strLastIndexOf "$x" / )" -eq 1 ]; then
                x="harisekhon$x"
            fi
        fi
        args="$args $x"
    done
    eval docker run --rm -ti "$args"
}

docker_get_container_ids(){
    local exclude_file=~/docker-perm.txt
    # if exclude file doesn't exist, grep fails entirely and we get no IDs returned, even pre-emptively replacing with /dev/null doesn't work, so omit the option entirely
    if [ -f "$exclude_file" ]; then
        exclude_file=" -f $exclude_file"
    fi
    # shellcheck disable=SC2086
    docker ps -a --format "{{.ID}} {{.Names}}" |
    grep -vi $exclude_file 2>/dev/null |
    awk '{print $1}'
}

dockerrmall(){
    # would use xargs -r / --no-run-if-empty but that is GNU only, doesn't work on Mac
    local ids
    ids="$(docker_get_container_ids)"
    if [ -n "$ids" ]; then
        # shellcheck disable=SC2086
        docker rm -f $ids
    fi
}

dockerrmigrep(){
    for x in "$@"; do
        docker images | grep "$x" | grep -v "<none>" | awk '{print $1":"$2}' | xargs docker rmi
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
    echo "$(dockerhub_search.py harisekhon -n 1000 | tail -n +2 | awk '{print $1}' | sort) $(sed 's/#.*//;/^[[:space:]]*$/d' ~/docker-images.txt | uniq_order_preserved.pl)"
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
        echo -e "\n\nsleeping for 1 hour\n\n"
        sleep 3600
    done
}

dockerpullr(){
    while true; do
        dockerpull "$@"
        wait
        echo -e "\n\nsleeping for 1 hour\n\n"
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
