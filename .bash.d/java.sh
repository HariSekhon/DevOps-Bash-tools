#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Sun Sep 9 21:20:49 2012 +0100
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
#                                    J a v a
# ============================================================================ #

srcdir="${srcdir:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
. "$srcdir/.bash.d/os_detection.sh"

if [ -n "${APPLE:-}" ]; then
    mac_export_java_home(){
        local version="$1"
        local args
        local java_home
        local java_library_base="/Library/Java/JavaVirtualMachines"
        local java_home_variable="JAVA_HOME"
        # for cross compiling to be found by gradle build
        if [ -n "$version" ]; then
            args="-v 1.$version"
            java_home_variable="JAVA${version}_HOME"
        fi
        if [ -x /usr/libexec/java_home ]; then
            # want arg splutting
            # shellcheck disable=SC2086
            java_home="$(/usr/libexec/java_home $args 2>/dev/null)"
            # $? is fine here thanks shellcheck
            # shellcheck disable=SC2181
            if [ $? -eq 0 ] && [ -d "$java_home" ]; then
                export "$java_home_variable"="$java_home"
                if [ -n "$DEBUG" ]; then
                    echo "Determined $java_home_variable from /usr/libexec/java_home to be '$java_home', update ~/.bashrc to optimize by setting this explicitly" >&2
                fi
            fi
        else
            ## java_home=/Library/Java/JavaVirtualMachines/jdk1.7.0_45.jdk/Contents/Home
            ## JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Home
            ## JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/Current/Home
            ## JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6/Home
            java_home="$(find "$java_library_base/"*1."$version"* -type d -name 'Home*' 2>/dev/null | tail -n1)"
            if [ -d "$java_home" ]; then
                export "$java_home_variable"="$java_home"
                if [ -n "$DEBUG" ]; then
                    echo "Determined $java_home_variable from searching $java_library_base to be '$java_home', update ~/.bashrc to optimize by setting this explicitly" >&2
                fi
            fi
        fi
    }
    if [ -z "$JAVA_HOME" ]; then
        mac_export_java_home
        mac_export_java_home 7
    fi
else # assume Linux
    #hardware_platform="$(uname -i)"
    # prefers Sun's JDK than OpenJDK, put it higher in the testing list
            # Sun's JRE
            # Sun's JDK
            # Open JDK
    # TODO: update / improve this for more recent linux desktops for those who still use them
#    for candidate in \
#            /usr/java/latest/jre \
#            /usr/java/latest/    \
#            /usr/lib/jvm/jre-openjdk \
#            /usr/lib/jvm/java-6-openjdk-$hardware_platform \
#            ; do
#        if   [ -x "$candidate/bin/java" ]; then
#            JAVA_HOME="$candidate"
#            break
#        fi
#    done
    if [ -z "$JAVA_HOME" ]; then
        if [ -n "$DEBUG" ]; then
            echo "WARNING: failed to find JAVA_HOME" >&2
        fi
        # last ditch effort, this will work with warnings
        if [ -x /usr/bin/java ]; then
            JAVA_HOME=/usr
        fi
    fi
    export JAVA_HOME
fi

export CLASSPATH="$CLASSPATH:$HOME/bin/java"

j(){
    for x in "$@"; do
        echo "javac $x" &&
        javac "$x"      &&
        echo "java ${x%.java} $x"  &&
        java "${x%.java}" "$x"
    done
}
