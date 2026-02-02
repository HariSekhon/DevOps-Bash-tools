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

get_os(){
    # shellcheck disable=SC3043
    local os >/dev/null 2>&1 || :
    if [ -n "${OS_DARWIN:-}" ]; then
        if is_mac; then
            os="$OS_DARWIN"
        fi
    elif [ -n "${OS_LINUX:-}" ]; then
        if is_linux; then
            os="$OS_LINUX"
        fi
    else
        os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    fi
    echo "$os"
}

get_arch(){
    # shellcheck disable=SC3043
    local arch >/dev/null 2>&1 || :
    arch="$(uname -m)"
    if [ "$arch" = x86_64 ]; then
        arch=amd64  # files are conventionally usually named amd64 not x86_64
    fi
    #if [ "$arch" = aarch64 ]; then
    #    arch=arm64
    #fi
    if [ -n "${ARCH_X86_64:-}" ]; then
        if [ "$arch" = amd64 ] || [ "$arch" = x86_64 ]; then
            arch="$ARCH_X86_64"
        fi
    fi
    if [ -n "${ARCH_X86:-}" ]; then
        if [ "$arch" = i386 ]; then
            arch="$ARCH_X86"
        fi
    fi
    if [ -n "${ARCH_ARM64:-}" ]; then
        if [ "$arch" = arm64 ]; then
            arch="$ARCH_ARM64"
        fi
    fi
    if [ -n "${ARCH_ARM:-}" ]; then
        if [ "$arch" = arm ]; then
            arch="$ARCH_ARM"
        fi
    fi
    if [ -n "${ARCH_OVERRIDE:-}" ]; then
        arch="$ARCH_OVERRIDE"
    fi
    echo "$arch"
}
