#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# intended only to be sourced by lib/utils.sh
#
# split from lib/utils.sh as this is specific to this repo

set -eu
[ -n "${DEBUG:-}" ] && set -x

if type isExcluded &>/dev/null; then
    return 0
fi

if [ -n "${BASH_EXCLUDE_FILES_FUNCTION:-}" ] &&
   [ -f "$BASH_EXCLUDE_FILES_FUNCTION" ] &&
   [[ "$BASH_EXCLUDE_FILES_FUNCTION" =~ \.sh$ ]] &&
   grep -q 'isExcluded()' "$BASH_EXCLUDE_FILES_FUNCTION"; then
    # shellcheck disable=SC1090
    . "$BASH_EXCLUDE_FILES_FUNCTION"
    return 0
fi

isExcluded(){
    local prog="$1"
    # this really is anything beginning with a star
    # shellcheck disable=SC2049
    [[ "$prog" =~ ^\* ]] && return 0
    [[ "$prog" =~ ^# ]]  && return 0
    #[[ "$prog" =~ /\. ]] && return 0
    [[ "$prog" =~ /\.git/ ]] && return 0
    [[ "$prog" =~ ^\.git/ ]] && return 0
    [[ "$prog" =~ \.external_modules/ ]] && return 0
    [[ "$prog" =~ /templates/ ]] && return 0
    [[ "$prog" =~ TODO ]] && return 0
    [[ "$prog" =~ /inc/Module/.*\.pm ]] && return 0
    # imported, minimal editing restricted to essentials only
    [[ "$prog" =~ getawless.sh ]] && return 0
    if [ -n "${EXCLUDE_FILES_REGEX:-}" ]; then
        if [[ "$prog" =~ $EXCLUDE_FILES_REGEX ]]; then
            return 0
        fi
    fi
    # optimization to avoid fork
    #if ! uname -s | grep -q Darwin; then
    if ! [[ "${OSTYPE:-}" == darwin* ]]; then
        if [[ "$prog" =~ /applescript/ ]]; then
            return 0
        fi
    fi
    # this external git check is expensive, skip it when in CI as using fresh git checkouts
    #is_CI && return 1
    ## shellcheck disable=SC2230
    #if type -P git &>/dev/null; then
    #    commit="$(git log "$prog" 2>/dev/null | head -n1 | grep 'commit' || :)"
    #    if [ -z "$commit" ]; then
    #        return 0
    #    fi
    #fi
    return 1
}
