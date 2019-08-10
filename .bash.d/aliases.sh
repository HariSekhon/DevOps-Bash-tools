#!/usr/bin/env bash
#  shellcheck disable=SC2139
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
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
#                              Bash General Aliases
# ============================================================================ #

export bashrc=~/.bashrc
alias r=". $bashrc"
alias bashrc="$EDITOR $bashrc && r"
alias vimrc="$EDITOR ~/.vimrc"
alias screenrc="$EDITOR ~/.screenrc"
alias aliases="$EDITOR $bashd/aliases.sh"
alias ae=aliases
alias be=bashrc
alias ve=vimrc
alias se=screenrc

# shellcheck disable=SC2154
export bashd="$srcdir/.bash.d"
alias bashd="cd $bashd"

#alias cleanshell="exec env - bash --rcfile /dev/null"
alias cleanshell="exec env - bash --norc --noprofile"
alias newshell="exec bash"
alias rr="newshell"

alias l33tmode="welcome; retmode=on; echo l33tm0de on"
alias leetmode=l33tmode

alias hist=history
alias clhist="HISTSIZE=0; HISTSIZE=5000"
alias nohist="unset HISTFILE"

export LS_OPTIONS="-F"
if [ -n "${APPLE:-}" ]; then
    export CLICOLOR=1 # equiv to using -G switch when calling
else
    export LS_OPTIONS="$LS_OPTIONS --color=auto"
    export PS_OPTIONS="$LS_OPTIONS -L"
fi

alias ls="ls $LS_OPTIONS"
# omit . and .. in listall with -A instead of -a
alias lA="ls -lA $LS_OPTIONS"
alias la="ls -la $LS_OPTIONS"
alias ll="ls -l $LS_OPTIONS"
alias lh="ls -lh $LS_OPTIONS"
alias lr="ls -ltrh $LS_OPTIONS"

alias cd..="cd .."
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
# use bare 'cd' instead, it's more standard
#alias ~="cd ~"

alias mv="mv -i"
alias cp="cp -i"
#alias rm="rm -i"
alias less="less -i"
alias l="less"
alias m="more"
alias vi="vim"
alias grep="grep --color=auto"
alias hosts="sudo $EDITOR /etc/hosts"
alias screen="screen -T $TERM"
#alias mt=multitail
#alias halt="shutdown -h now -P"
# my pytools github repo
alias ht="headtail.py"

alias a="ansible"
alias bc="bc -l"
alias chromekill="pkill -f 'Google Chrome Helper'"
alias eclipse="|/eclipse/Eclipse.app/Contents/MacOS/eclipse";
alias visualvm="~/visualvm/bin/visualvm"

# for piping from grep
alias uniqfiles="sed 's/:.*//;/^[[:space:]]*$/d' | sort -u"

export etc=~/etc
alias etc="cd $etc"

alias distro="cat /etc/*release /etc/*version 2>/dev/null"
alias trace=traceroute
alias t="$EDITOR $HOME/tmp"
# causes more problems than it solves on a slow machine missing the prompt
#alias y=yes
alias t2="$EDITOR $HOME/tmp2"
alias t3="$EDITOR $HOME/tmp3"
alias tg="traceroute www.google.com"
#alias sec="ps -ef| grep -e arpwatc[h] -e swatc[h] -e scanlog[d]"

export lab=~/lab
alias lab="cd $lab"

alias jenkins_cli="java -jar ~/jenkins-cli.jar -s http://jenkins:8080"
alias backup_jenkins="rsync -av root@jenkins:/jenkins_backup/*.zip '~/jenkins_backup/'"

alias record=script

export downloads=~/Downloads
export down="$downloads"
alias Down="cd $downloads"
alias down=Down

alias desktop=Desktop
alias desk=Desktop

for v in ~/github/pytools/validate_*.py; do
    z="${v##*/}"
    z="${z#validate_}"
    z="${z%.py}"
    # shellcheck disable=SC2140
    alias "v$z"="$v"
done
