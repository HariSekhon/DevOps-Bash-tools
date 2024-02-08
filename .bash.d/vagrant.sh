#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Thu Mar 14 12:42:17 2013 +0000
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
#                                 V a g r a n t
# ============================================================================ #

#export VAGRANT_HOME=~/vagrant
#export VAGRANT_BOXES=~/boxes

# $bash_tools defined in adjacent shell modules
# shellcheck disable=SC2154
export vagrant="$bash_tools/vagrant"

#alias cd_vagrant='[ "$PWD" = "$VAGRANT_HOME" ] || cd "$VAGRANT_HOME"'
#alias cd_vagrant='cd "$VAGRANT_HOME"'
alias cd_vagrant='cd "$vagrant"'
alias cdv=cd_vagrant
alias vhome=cd_vagrant
#alias v='cd_vagrant; vagrant'
# 'v' is aliased to vim now as it's used much more often
#alias v='vagrant'
alias vag='vagrant'
#alias vf='cd_vagrant; vim Vagrantfile; vagrant_gen_etc_hosts; eval "$(vagrant_gen_aliases)"'
alias vst='vagrant status'
alias vrun='vst | grep running'
# vr is aliased to vbox_running in virtualbox.sh
alias vrr='vrun'
#alias vssh='cd_vagrant; ssh_func vagrant ssh'
#alias vssh='cd_vagrant; vagrant ssh'
alias vssh='vagrant ssh'
alias boxes='cd $VAGRANT_BOXES'

while read -r directory; do
    # shellcheck disable=SC2139,SC2140
    alias "v${directory##*/}"="cd $directory"
done < <(find "$vagrant" -maxdepth 1 -type d)

# see ../vagrant_hosts.sh for similar parsing
#
#vagrant_parse_hosts(){
#    if ! [ -f "$VAGRANT_HOME/Vagrantfile" ]; then
#        return
#    fi
#    #grep '[^#]*config.vm.define' "$VAGRANT_HOME/Vagrantfile" | awk -F'"' '{print $2}'
#    sed 's/#.*//;/^[[:space:]]*$/d' "$VAGRANT_HOME/Vagrantfile" |
#    grep -e host_name -e network |
#    grep -B1 -e network |
#    grep -v -e "^--" -e "default_hostname" |
#    sed 's/^.*[[:space:]]"//;s/"//' |
#    tr '\n' ' ' |
#    perl -pn -e 's/(\.\d+)\s/$1\n/g'
#}
#
#vagrant_gen_aliases(){
#    vagrant_parse_hosts |
#    while read -r host ip rest; do
#        if ! type "$host" &>/dev/null; then
#            #echo "alias $host='ssh root@$host'"
#            #echo "alias $host='vups $host'"
#            echo "alias $host='vssh $host'"
#        fi
#    done
#}
#
# don't really use these aliases to vagrant boxes any more
#eval "$(vagrant_gen_aliases)"

#vagrant_gen_etc_hosts(){
#    vagrant_parse_hosts |
#    while read -r host ip rest; do
#        if [ -n "${rest:-}" ]; then
#            echo "error third token '$rest' detected from pipe line '$ip $host $rest'"
#            return 1
#        fi
#        [ "${host}" = "localhost" ] && continue
#        host_record="$ip $host.local $host"
#        # sudo auto-defined in .bashrc
#        # shellcheck disable=SC2154
#        $sudo perl -pi -e "s/^$ip\\s+.*/$host_record/" /etc/hosts
#        if [ -n "$ip" ]; then
#            grep -q "^$host_record" /etc/hosts ||
#            $sudo sh -c "echo '$host_record' >> /etc/hosts"
#        else
#            echo "no ip passed in pipe for host '$host'! "
#            return 1
#        fi
#    done
#}

vagrant_usage(){
    if [ -z "$1" ]; then
        echo "usage: ${FUNCNAME[1]} <vm_name>"
        return 1
    fi
}

vup(){
    #vagrant_usage "$1" || return 1
    vagrant up "$@"
}

vre(){
    vagrant_usage "$1" || return 1
    vagrant reload "$@"
}

vressh(){
    vagrant_usage "$1" || return 1
    vagrant reload "$1"
    vagrant ssh "$1"
}

vsus(){
    #vagrant_usage "$1" || return 1
    vagrant suspend "$@"
}

vres(){
    #vagrant_usage "$1" || return 1
    vagrant resume "$@"
}

#alias vsusall="vsus $(vst | grep running | awk '{print $1}')"
vsusall(){
    local running_vms=()
    read -r -a running_vms <<< "$(vst | grep running | awk '{print $1}')"
    [ ${#running_vms} -gt 0 ] || return 0
    vsus "${running_vms[@]}"
}
alias vsusa=vsusall

vupssh(){
    vagrant_usage "$1" || return 1
    local status
    status="$(vst "$1")"
    if grep -Eq "^$1[[:space:]]" <<< "$status"; then
        grep -Eq "^$1[[:space:]]+running" <<< "$status" || vup "$1"
    else
        echo "VM not found: $1"
        return 1
    fi
    #vup $1
    vssh "$1"
}
alias vups="vupssh"

vhalt(){
    #vagrant_usage "$1" || return 1
    vagrant halt "$@"
}

vrhalt(){
    # want splitting
    # shellcheck disable=SC2046
    vhalt "$@" $(vagrant status | awk '/running/ {print $1}')
}

vrsus(){
    # want splitting
    # shellcheck disable=SC2046
    vsus $(vagrant status | awk '/running/ {print $1}')
}

vdestroy(){
    #vagrant_usage "$1" || return 1
    vagrant destroy --force "$@"
}

vdestroyup(){
    vdestroy "$@" || :
    vup "$@"
}

vdestroyups(){
    vdestroy "$@" || :
    vups "$@"
}

vprovision(){
    #vagrant_usage "$1" || return 1
    vagrant provision "$@"
}

vprov(){
    vprovision "$@"
}

whenvdown(){
    vst |
    while grep "$1.*running"; do
        sleep 0.1
    done
}
