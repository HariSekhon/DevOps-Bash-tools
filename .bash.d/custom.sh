#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2006-06-28 23:25:09 +0100 (Wed, 28 Jun 2006)
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
#                                  C u s t o m
# ============================================================================ #

# Stuff that's overly custom and only sourced for my own user
#
# eg. $USER specific env vars and too short less generic aliases

if ! [[ $USER =~ hari|sekhon ]]; then
    return 0
fi

# put secret tokens in vars() or ~/.bashrc.local instead
export GITHUB_USER=HariSekhon
export TRAVIS_USER="HariSekhon"
export BUILDKITE_ORGANIZATION=hari-sekhon
export SEMAPHORE_CI_ORGANIZATION=harisekhon

alias tll="travis_last_log.py"

# can't set this to just the shorter 'go' or 'perl' because it'll clash with the actual commands
alias goto=go_tools
alias pyt=pytools
alias to=perl_tools

# shellcheck disable=SC2154
export plugins="$github/nagios-plugins"
export pl="$plugins"
alias plugins='sti pl; cd $pl'
alias pl=plugins

# travis_last_log.py should be in $PATH from DevOps-Python-tools repo
alias pll="travis_last_log.py HariSekhon/nagios-plugins"
export pl2="${plugins}2"
alias pl2='sti pl2; cd $pl2'

alias pytl="tll /pytools"
alias pyt2="pytools2"
alias pyl="pylib"
alias pyll="tll /pylib"

alias tol="tll /tools"
alias to2="tool2"

# clashes with the D2 diagramming language
#alias d2="Dockerfiles2"
alias Dockerfilesl="tll /Dockerfiles"
