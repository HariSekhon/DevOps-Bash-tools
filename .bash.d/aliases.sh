#!/usr/bin/env bash
# shellcheck disable=SC2230,SC2139
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2006 (forked from .bashrc)
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
#                         G e n e r a l   A l i a s e s
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# shellcheck disable=SC1090,SC1091
#. "$bash_tools/.bash.d/paths.sh"

# manual local aliases
# shellcheck disable=SC1090,SC1091
[ -f ~/.aliases ] && . ~/.aliases

# bash_tools defined in .bashrc
# shellcheck disable=SC2154
export bashrc=~/.bashrc
export bashrc2="$bash_tools/.bashrc"
alias reload='. $bashrc'
alias r='reload'
alias rq='set +x; . $bashrc; set -x'
alias bashrc='$EDITOR $bashrc && reload'
alias bashrc2='$EDITOR $bashrc2 && reload'
alias bashrclocal='$EDITOR $bashrc.local; reload'
alias bashrc3=bashrclocal
alias v='vim'
alias vimrc='$EDITOR ~/.vimrc'
alias screenrc='$EDITOR ~/.screenrc'
alias aliases='$EDITOR $bashd/aliases.sh'
alias ae=aliases
alias be=bashrc
alias be2=bashrc2
alias be3=bashrc3
alias se=screenrc
alias ve=vimrc
alias creds='$EDITOR ~/.env/creds'
alias pbc=pbcopy
alias pbp=pbpaste
# keep emacs with no window, use terminal, not X, otherwise I'd run xemacs...
#alias emacs="emacs -nw"
#em(){ emacs "$@" ; }
#alias em=emacs
#alias e=em
#xe(){ xemacs $@ & }
#alias x=xe

# from DevOps-Perl-tools repo which must be in $PATH
# done via functions.sh now
#alias new=new.pl

# not present on Mac
#type tailf &>/dev/null || alias tailf="tail -f"
alias tailf="tail -f"  # tail -f is better than tailf anyway
alias mv='mv -i'
alias cp='cp -i'
#alias rm='rm -i'
# allows to re-use custommized less behaviour throughout profile without duplicating options
#less='less -RFXig'
#alias less='$less'
export LESS="-RFXig --tabs=4"
# will require LESS="-R"
if type -P pygmentize &>/dev/null; then
    # shellcheck disable=SC2016
    export LESSOPEN='| "$bash_tools/python/pygmentize.sh" "%s"'
fi
alias l='less'
alias m='more'
alias vi='vim'
# used by vagrant now
#alias v='vim'
alias grep='grep --color=auto'
# in functions.sh for multiple args now
#alias envg="env | grep -i"
alias dec="decomment.sh"

alias hosts='sudo $EDITOR /etc/hosts'

alias path="echo \$PATH | tr ':' '\\n' | less"
alias paths=path

alias tmp="cd /tmp"

alias mksupportdir="mkdir -v support-bundle-$(date '+%F_%H%M')"

# not as compatible, better to call pypy explicitly or in #! line
#if type -P pypy &>/dev/null; then
#    alias python=pypy
#fi

# shellcheck disable=SC2139
bt="$(dirname "${BASH_SOURCE[0]}")/.."
export bt
alias bt='sti bt; cd $bt'

# shellcheck disable=SC2154
export bashd="$bash_tools/.bash.d"
alias bashd='sti bashd; cd $bashd'

#alias cleanshell='env - bash --rcfile /dev/null'
alias cleanshell='env - bash --norc --noprofile'
alias newshell='exec bash'
alias rr='newshell'

alias record=script

alias l33tmode='welcome; retmode=on; echo l33tm0de on'
alias leetmode=l33tmode

alias hist=history
alias clhist='HISTSIZE=0; HISTSIZE=5000'
alias nohist='unset HISTFILE'
alias histgrep='history | grep'

export LS_OPTIONS='-F'
if is_mac; then
    export CLICOLOR=1 # equiv to using -G switch when calling
else
    export LS_OPTIONS="$LS_OPTIONS --color=auto"
    export PS_OPTIONS="$LS_OPTIONS -L"
fi

alias ls='ls $LS_OPTIONS'
# omit . and .. in listall with -A instead of -a
alias lA='ls -lA $LS_OPTIONS'
alias la='ls -la $LS_OPTIONS'
alias ll='ls -l $LS_OPTIONS'
alias lh='ls -lh $LS_OPTIONS'
alias lr='ls -ltrh $LS_OPTIONS'
alias ltr='lr'
alias lR='ls -lRh $LS_OPTIONS'

# shellcheck disable=SC2086
lw(){ ls -lh $LS_OPTIONS "$(type -P "$@")"; }

# shellcheck disable=SC2086,SC2012
lll(){ ls -l "$(readlink -f "${@:-.}")" | less -R; }

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
#up(){
#    local times="${1:-1}"
#    if ! [[ "$times" =~ ^[[:digit:]]$ ]]; then
#        echo "How many directories to go up"
#        echo
#        echo "usage: up <num>"
#        return 1
#    fi
#    while [ "$times" -gt 0 ]; do
#        cd ..
#        times=$((times - 1))
#    done
#}
# use bare 'cd' instead, it's more standard
#alias ~='cd ~'

alias screen='screen -T $TERM'
#alias mt=multitail
#alias halt='shutdown -h now -P'
# my pytools github repo
alias ht='headtail.py'

alias run='run.sh'

# ============================================================================ #
#           GitHub / GitLab / BitBucket / Azure DevOps repo checkouts
# ============================================================================ #

export github=~/github
export gitlab=~/gitlab
export azure_devops=~/azure-devops
alias github="sti github; cd '$github'";
export work="$github/work"
alias work="sti work; cd '$work'"

alias btup="bt; u; cd -"

export bitbucket=~/bitbucket
alias bitb='cd $bitbucket'
# clashes with bitbucket-cli
#alias bitbucket='cd $bitbucket'
# used to gitbrowse to bitbucket now in git.sh
#alias bb=bitbucket

alias diag=diagrams

aliasdir(){
    local directory="$1"
    local suffix="${2:-}"
    [ -d "$directory" ] || return 0
    name="${directory##*/}"
    name="${name//-/_}"
    name="${name//./_}"
    name="${name// /}"
    # alias terraform /tf -> terra
    if [[ "$name" =~ ^(terraform|tf)$ ]]; then
        name="terra"
    fi
    if [ -z "${!name:-}" ]; then
        export "$name"="$directory"
    fi
    # don't clash with any binaries
    #if ! type -P "${name}${suffix}" &>/dev/null; then
    # don't clash with binaries or any previous defined aliases or functions
    if ! type "${name}${suffix}" &>/dev/null; then
        # shellcheck disable=SC2139,SC2140
        alias "${name}${suffix}"="sti $name; cd $directory"
    elif ! type "g${name}${suffix}" &>/dev/null; then
        # shellcheck disable=SC2139,SC2140
        alias "g${name}${suffix}"="sti $name; cd $directory"
    fi
}

for basedir in "$github" "$gitlab" "$bitbucket" "$azure_devops"; do
    if [ -d "$basedir" ]; then
        for directory in "$basedir/"*; do
            aliasdir "$directory"
            if [[ "$directory" =~ /work$ ]]; then
                for workdir in "$directory/"*; do
                    aliasdir "$workdir" "w"  # work dirs should have a w suffix
                done
            fi
        done
    fi
done


doc_alias(){
    local docpath="$1"
    local prefix="${2:-d}"
    [ -f "$docpath" ] || return 1
    docfile="${docpath##*/}"
    # slows down shell creation, will drain battery
#    if [ -L "$docpath" ]; then
#        # brew install coreutils to get greadlink since Mac doesn't have readlink -f
#        if type -P greadlink &>/dev/null; then
#            docfile="$(greadlink -f "$docpath")"
#        else
#            docfile="$(readlink -f "$docpath")"
#        fi
#    fi
    #local count=0
    #[ -f ~/docs/$docfile ] && ((count+=1))
    #[ -f "$github/docs/$docfile" ] && ((count+=1))
    #[ -f "$bitbucket/docs/$docfile" ] && ((count+=1))
    #if [ $count -gt 1 ]; then
    #    echo "WARNING: $docfile conflicts with existing alias, duplicate doc '$docfile' among ~/docs, ~/github/docs, ~/bitbucket/docs?"
    #    return
    #fi
    local shortname="${docfile%.md}"
    local shortname="${shortname%.txt}"
    # shellcheck disable=SC2139,SC2140
    alias "${prefix}${shortname}"="ti ${docpath##*/}; \$EDITOR $docpath"
}

for x in ~/docs/* "$github"/docs/* "$bitbucket"/docs/*; do
    doc_alias "$x" || :
done

for x in ~/knowledge/* "$github"/knowledge/* "$bitbucket"/knowledge/*; do
    doc_alias "$x" k || :
done

# ============================================================================ #

# set in ansible.sh
#alias a='ansible -Db'
alias anonymize='anonymize.py'
alias an='anonymize -a'
alias bc='bc -l'
alias chromekill='pkill -f "Google Chrome Helper"'
alias eclipse='~/eclipse/Eclipse.app/Contents/MacOS/eclipse';
alias visualvm='~/visualvm/bin/visualvm'

alias tmpl=templates

# using brew version on Mac
pmd_opts="-R rulesets/java/quickstart.xml -f text"
if is_mac; then
    # yes evaluate $pmd_opts here
    # shellcheck disable=SC2139
    pmd="pmd $pmd_opts"
else
    for x in ~/pmd-bin-*; do
        if [ -f "$x/bin/run.sh" ]; then
            # yes evaluate $x here, and don't export it's lazy evaluated in alias below
            # shellcheck disable=SC2139,SC2034
            pmd="$x/bin/run.sh pmd $pmd_opts"
        fi
    done
fi
alias pmd='$pmd'

# from DevOps Perl tools repo - like uniq but doesn't require pre-sorting keeps the original ordering
# Devops Golang tools uniq2 should be on path instead now
#alias uniq2=uniq_order_preserved.pl

# for piping from grep
alias uniqfiles="sed 's/:.*//;/^[[:space:]]*$/d' | sort -u"

export etc=~/etc
alias etc='cd $etc'


alias distro='cat /etc/*release /etc/*version 2>/dev/null'
alias trace=traceroute
alias t='$EDITOR ~/tmp'
# causes more problems than it solves on a slow machine missing the prompt
#alias y=yes
alias t2='$EDITOR ~/tmp2'
alias t3='$EDITOR ~/tmp3'
#alias tg='traceroute www.google.com'
#alias sec='ps -ef| grep -e arpwatc[h] -e swatc[h] -e scanlog[d]'


export lab=~/lab
alias lab='cd $lab'

# Auto-alias uppercase directories in ~ like Desktop and Downloads
#for dir in $(find ~ -maxdepth 1 -name '[A-Z]*' -type d); do [ -d "$dir" ] && alias ${dir##*/}="cd '$dir'"; done

export Downloads=~/Downloads
export Documents=~/Documents
alias Downloads='cd "$Downloads"'
alias Documents='cd "$Documents"'
export down="$Downloads"
export docu="$Documents"
alias down='cd "$Downloads"'
alias docu='cd "$Documents"'
alias doc='cd ~/docs'

export desktop=~/Desktop
export desk="$desktop"
alias desktop='cd "$desktop"'
alias desk=desktop

export screenshots=~/Desktops/Screenshots
alias screenshots='cd "$screenshots"'

export bin=~/bin
alias bin="cd $bin"

alias todo='ti T; $EDITOR ~/TODO'
alias TODO="todo"
alias don='ti D; $EDITOR ~/DONE'
alias DON=don

# drive => Google Drive
export google_drive=~/drive
export drive="$google_drive"
alias drive='cd "$drive"'

for v in ~/github/pytools/validate_*.py; do
    z="${v##*/}"
    z="${z#validate_}"
    z="${z%.py}"
    # needs to expand now for dynamic alias creation
    # shellcheck disable=SC2139,SC2140
    alias "v$z"="$v"
done

# in some environments I do ldap with Kerberos auth - see ldapsearch.sh script at top level which is more flexible with pre-tuned environment variables
#alias ldapsearch="ldapsearch -xW"
#alias ldapadd="ldapadd -xW"
#alias ldapmodify="ldapmodify -xW"
#alias ldapdelete="ldapdelete -xW"
#alias ldappasswd="ldappasswd -xW"
#alias ldapwhoami="ldapwhoami -xW"
#alias ldapvi="ldapvi -b dc=domain,dc=local -D cn=admin,dc=domain,dc=local"

alias fluxkeys='$EDITOR ~/.fluxbox/keys'
alias fke=fluxkeys
alias fluxmenu='$EDITOR ~/.fluxbox/mymenu'
alias fme=fluxmenu
alias mymenu=fluxmenu
alias menu=mymenu
