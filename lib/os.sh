#!/bin/sh
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

set -eu
[ -n "${DEBUG:-}" ] && set -x

is_linux(){
    if [ "$(uname -s)" = "Linux" ]; then
        return 0
    fi
    return 1
}

is_mac(){
    if [ "$(uname -s)" = "Darwin" ]; then
        return 0
    fi
    return 1
}

is_windows(){
    case "$(uname -s)" in
        CYGWIN*|MINGW*|MSYS*)   return 0
                                ;;
    esac
    return 1
}

linux_only(){
    if ! is_linux; then
        die "Only Linux is supported"
    fi
}

mac_only(){
    if ! is_mac; then
        die "Only macOS is supported"
    fi
}

windows_only(){
    if ! is_windows; then
        die "Only Windows is supported"
    fi
}
