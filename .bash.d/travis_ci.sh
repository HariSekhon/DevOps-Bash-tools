#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Wed Jan 20 15:28:12 2016 +0000
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
#                               T r a v i s   C I
# ============================================================================ #

# Travis bash autocomplete
# adapted from Travis ruby gem auto-added to end of ~/.bashrc
# shellcheck disable=SC1090
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh

# for auto authentication using Travis CI tools like travis_last_log.py and travis_debug_session.py
#export TRAVIS_TOKEN=...

travis_debug(){
    # code has better automatic handling, doesn't need this now
    #if grep '/' <<< "$1" &>/dev/null; then
    #    travis_debug_session.py -r "$1" ${@:2}
    #else
    #    travis_debug_session.py -J "$1" ${@:2}
    #fi
    travis_debug_session.py "$@"
}
