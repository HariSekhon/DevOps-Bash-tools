#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2010 - 2012 (forked from .bashrc)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

type is_linux &>/dev/null &&
type isMac &>/dev/null &&
type isGoogleCloudShell &>/dev/null &&
type isAzureCloudShell &>/dev/null &&
return

get_os(){
    if [ -z "${operating_system:-}" ] ||
       ! [[ "$operating_system" =~ ^(Linux|Darwin)$ ]]; then
        operating_system="$(uname -s)"
        export operating_system
    fi
}

isLinux(){
    [ -n "${LINUX:-}" ] && return 0
    get_os
    if [ "$operating_system" = Linux ]; then
        export LINUX=1
        return 0
    fi
    return 1
}

isMac(){
    [ -n "${OSX:-}" ] && return 0
    get_os
    if [ "$operating_system" = Darwin ]; then
        export APPLE=1
        export OSX=1
        return 0
    fi
    return 1
}

isGoogleCloudShell(){
    [ -n "${GOOGLE_CLOUD_SHELL:-}" ] && return 0
    get_os
    [ "$operating_system" = Linux ] || return 1
    # DEVSHELL_PROJECT_ID is more likely to be unique to GCP Cloud Shell environment
    #if [ -n "${GOOGLE_CLOUD_PROJECT:-}" ]; then
    if [ -n "${DEVSHELL_PROJECT_ID:-}" ]; then
        export GOOGLE_CLOUD_SHELL=1
        return 0
    fi
    return 1
}

isAzureCloudShell(){
    [ -n "${AZURE_CLOUD_SHELL:-}"  ] && return 0
    get_os
    [ "$operating_system" = Linux ] || return 1
    if [ -n "${ACC_TERM_ID:-}" ]; then
        export AZURE_CLOUD_SHELL=1
        return 0
    fi
    return 1
}

# for compatibility to use the same names as non-interactive lib/
is_linux(){
    isLinux
}

is_mac(){
    isMac
}

is_google_cloud_shell(){
    isGoogleCloudShell "$@"
}

is_azure_cloud_shell(){
    isAzureCloudShell "$@"
}

# make this safe to import in set -e scripts
is_linux || :
isMac || :
isGoogleCloudShell || :
isAzureCloudShell || :
