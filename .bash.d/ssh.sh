#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 - 2012 (forked from .bashrc)
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
#                                     S S H
# ============================================================================ #

#ssh() { set -o xtrace ; command ssh "$@" <<< "$(cat .bashrc_remote)" ; }

alias sshconfig='$EDITOR ~/.ssh/config'
alias sshcfg=sshconfig

# ssh-add
ssha(){
    ssh_agent
    #num_keys="$(ssh-add -l | grep -Ec "(rsa|dsa)")"
    #if [ "$num_keys" -lt 1 ]; then
    #    ssh-add ~/.ssh/id_[rd]sa
    #else
    #    return 0
    #fi
    for key in ~/.ssh/id_[rd]sa; do
        key_fingerprint="$(ssh-keygen -lf "$key" | awk '{print $2}')"
        if ! ssh-add -l | grep -Fq "$key_fingerprint"; then
            ssh-add "$key"
        fi
    done
}

ssh_func(){
    ssha
    if [ "$1" = "ssh" ] || [ "$1" = "vagrant" ]; then
        local n=2
        [ "$1" = "vagrant" ] && ((n+=1))
        until [ "$n" -gt "$#" ]; do
            case ${!n} in
                -*) :
                    ;;
                 *) grep -Eq "^[0-9]+$" <<< "${!n}" || break
                    ;;
            esac
            ((n+=1))
        done
    fi
    local t="${!n}" # indirect reference to variable number by evaluating
    t="${t##*@}"
    t="${t%%.*}"
    title "$t"
    command "$1" "${@:2}"
    [ "$1" != "scp" ] && title "$LAST_TITLE"
}
alias ssh="ssh_func ssh"
alias sshl="ssh-add -l"
alias sshni="ssh_func ssh -oPreferredAuthentications=publickey -oStrictHostKeyChecking=no"
alias scp="ssh_func scp"
alias sftp="ssh_func sftp"
#alias sshc="ssh_custom"

safe_ssh(){
    if [ $# -lt 1 ]; then
        echo "usage: safe_ssh [user@]hostname"
        return 1
    fi
    host="${1##*@}"
    if grep -q '@' <<< "$1"; then
        user="${1%%@*}"
    else
        user=root
    fi
    #keys=`ssh -oStrictHostKeyChecking=no $@ 'for x in rsa dsa; do ssh-keygen -l -f /etc/ssh/ssh_host_${x}_key ; done' 2>&1`
    #keys=`ssh -oStrictHostKeyChecking=no $@ 'for x in rsa dsa; do cat /etc/ssh/ssh_host_${x}_key ; done' 2>&1`
    keys="$(ssh "$user@$host" 'for x in rsa dsa; do cat /etc/ssh/ssh_host_${x}_key.pub ; done')"
    rsa_key="$(echo "$keys" | awk '/ssh-rsa/ {print $1" "$2}')"
    dsa_key="$(echo "$keys" | awk '/ssh-dsa/ {print $1" "$2}')"
    known_key="$(grep "${@##*@}" ~/.ssh/known_hosts | awk '{print $2" "$3}' | sort -u)"
    echo
    if [ "$rsa_key" = "$known_key" ]; then
        echo "OK: Host rsa key matches known key"
    elif [ "$dsa_key" = "$known_key" ]; then
        echo "OK: Host dsa key matches known key"
    else
        echo 'WARNING: known ssh key for '"$1"' does not match either rsa or dsa keys obtained from server!!!'
        echo "Known Key: $known_key"
        echo "RSA   Key: $rsa_key"
        echo "DSA   Key: $dsa_key"
    fi
}
alias sssh=safe_ssh

check_sshkey(){
    for x in "$@"; do
        grep "$x" ~/.ssh/known_hosts |
        sort |
        while read -r host id known_key; do
            scanned_key="$(ssh-keyscan "$host" | awk "/^$host $id / {print \$3}")"
            if [ "$scanned_key" != "$known_key" ]; then
                echo -e "\\nMISMATCH: $host\\nknown key: $known_key\\nscanned_key:$scanned_key\\n\\n"
            fi
        done
    done
}

#update_sshkey(){
#    host="$1"
#    id="$2"
#    key="$3"
#    perl -pi -e "s/^$host .*/$host $id $key/" ~/.ssh/known_hosts
#}

ressh(){
    # FIXME: a cheat, it should be set properly but ssh in retry doesn't look like it's triggers ssh_func properly
    title "$1"
    retry ssh "$@"
    title "$LAST_TITLE"
}

rissh(){
    if [ $# -lt 1 ]; then
        echo "rissh <hostname>"
        return 1
    fi
    cleankey "$@"
    ressh "$@" -oStrictHostKeyChecking=no
}

issh(){
    if [ $# -lt 1 ]; then
        echo "issh <hostname>"
        return 1
    fi
    cleankey "$@"
    ssh -oStrictHostKeyChecking=no "$@"
}

bouncessh(){
    checkhost "$1" || return 1
    title "$1"
    whendown "$1"
    ressh "$@"
}
alias bssh=bouncessh

bouncerissh(){
    checkhost "$1" || return 1
    title "$1"
    whendown "$1"
    rissh "$@"
}
alias brissh=bouncerissh
alias bissh=bouncerissh

rekey(){
    [ -n "$1" ] || { echo "usage: rekey host"; return 1; }
    cleankey "$1"
    ssh-keyscan -t rsa "$1" | grep "^$1 ssh-rsa" >> ~/.ssh/known_hosts
    ssh-keyscan -t dsa "$1" | grep "^$1 ssh-dss" >> ~/.ssh/known_hosts
}

sshkey(){
    local key=~/.ssh/id_rsa.pub
    # now available on Mac, but my tried and tested function of years gone by dedupes the keys
#    if type -P ssh-copy-id; then
#        ssh-copy-id -i "$key" "$@"
#    else
        ssh "$@" '
            umask 077;
            [ -d ~/.ssh ] || mkdir -p ~/.ssh;
            key=`cat`;
            # my version is better than what ssh-copy-id did it would add duplicate keys
            if ! grep "$key" ~/.ssh/authorized_keys >/dev/null 2>&1; then
                echo $key >> ~/.ssh/authorized_keys;
            fi;
            chmod 0600 ~/.ssh/authorized_keys
            # this line was the only advantage ssh-copy-id script had
            test -x /sbin/restorecon && /sbin/restorecon ~/.ssh ~/.ssh/authorized_keys >/dev/null 2>&1 || true
        ' < "$key"
#    fi
}

sshkeygo(){
    sshkey "$@"
    ssh "$@"
}

sshkey2(){
    sshkeygo "$@"
}

cleankey(){
    if [ $# -lt 1 ]; then
        echo "usage: cleankey regex"
        return 1
    fi
    for x in "$@"; do
        ssh-keygen -R "$x"
        local aliasname
        aliasname="$(host "$x" | awk '/is an alias for/ {print $6}')"
        if [ -n "$aliasname" ]; then
            ssh-keygen -R "$aliasname"
            ssh-keygen -R "${aliasname%%.*}"
        fi
        continue
#        local ip
#        ip="$(host -W 1 "$x" | grep address)"
#        if [ $? -eq 0 ]; then
#            ip="$(cut -d" " -f 4 <<< "$ip")"
#            perl -pi -e 's/^\[?[^,]+\]?(:\d+)?,\[?'"$ip"'\]?(:\d)? .*$//;s/^'"$ip"' .*$//' ~/.ssh/known_hosts
#        fi
#        # need to leave second deletion just in case as you may want to specify just the ip address
#        #perl -pi -e 's/^\[?'"$x"'\]?(:\d+)?\[,\s.*$//;s/^.*[^,]+,'"$x"' .*$//' ~/.ssh/known_hosts
#        perl -pi -e 's/^'"$x"'\s.*$//;s/^.*[^,]+,'"$x"' .*$//' ~/.ssh/known_hosts
    done
}

keyremove(){
    for x in "$@"; do
        # shellcheck disable=SC1117
        ssh -o "PasswordAuthentication no" "$x" '
            for y in ~/.ssh/authorized_keys*; do
                if [ -f "$y" ]; then
                    perl -pi -e '"'s/ssh-rsa .*= hari@.*\n//'"' "$y"
                fi
            done
        '
    done
}

#keyremoveall(){
#    for x in "$@"; do
#        for y in root hari oracle; do
#            keyremove "$y@$x"
#        done
#    done
#}
