#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: Sun Sep 9 21:20:49 2012 +0100
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
#                                    J a v a
# ============================================================================ #

bash_tools="${bash_tools:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090,SC1091
. "$bash_tools/.bash.d/os_detection.sh"

# shellcheck disable=SC1090,SC1091
#type add_PATH &>/dev/null || . "$bash_tools/.bash.d/paths.sh"

add_PATH CLASSPATH ~/bin/java

# turn off those annoying Java 11 warnings when using Groovy scripting
export GROOVY_TURN_OFF_JAVA_WARNINGS=true

#alias rmclass='rm -fv *.class'
alias rmclass='find . -type f -name "*.class" -exec rm -fv {} \;'

if is_mac; then
    mac_export_java_home(){
        local version="$1"
        local args=()
        local java_home
        local java_library_base="/Library/Java/JavaVirtualMachines"
        local java_home_variable="JAVA_HOME"
        # for cross compiling to be found by gradle build
        if [ -n "$version" ]; then
            args+=(-v "1.$version")
            java_home_variable="JAVA${version}_HOME"
        fi
        if [ -x /usr/libexec/java_home ]; then
            # want arg splutting
            java_home="$(/usr/libexec/java_home "${args[@]}" 2>/dev/null)"
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
elif is_linux; then
    if [ -z "$JAVA_HOME" ]; then
        # RHEL / CentOS
        if type -P alternatives &>/dev/null; then
            java_home="$(alternatives --list | awk '/^java[[:space:]]/{print $3; exit}' | sed 's,\(/jre\)\?/bin/java$,,')"
            if [ -n "$java_home" ]; then
                export JAVA_HOME="$java_home"
            fi
        # Debian / Ubuntu
        elif type -P update-alternatives &>/dev/null; then
            java_home="$(update-alternatives --list java 2>/dev/null | sed 's,\(/jre\)\?/bin/java$,,' | head -n1)"
            if [ -n "$java_home" ]; then
                export JAVA_HOME="$java_home"
            fi
        # Alpine / Other / or if all else fails
        else
            # prefers Sun's JDK to OpenJDK, put it higher in the testing list
            # readlink -f => /etc/alternatives/java_sdk => /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.222.b10-0.el7_6.x86_64
            for java_home in \
                    /usr/java/latest    \
                    /usr/java/latest/jre \
                    /usr/lib/jvm/java \
                    /usr/lib/jvm/java-openjdk \
                    /usr/lib/jvm/jre-openjdk \
                    /usr/lib/jvm/jre \
                    /usr/lib/jvm/default-jvm \
                    ; do       # default-jvm is on Alpine
                if   [ -x "$java_home/bin/java" ]; then
                    export JAVA_HOME="$java_home"
                    break
                fi
            done
            if [ -z "$JAVA_HOME" ]; then
                if [ -n "$DEBUG" ]; then
                    echo "WARNING: failed to find JAVA_HOME" >&2
                fi
                # last ditch effort, this will work with warnings
                if [ -x /usr/bin/java ]; then
                    export JAVA_HOME=/usr
                fi
            fi
        fi
    fi
fi

# haven't used this in many years
#j(){
#    for x in "$@"; do
#        echo "javac $x" &&
#        javac "$x"      &&
#        echo "java ${x%.java} $x"  &&
#        java "${x%.java}" "$x"
#    done
#}

if ! type sdk &>/dev/null && [ -s ~/.sdkman/bin/sdkman-init.sh ]; then
    # shellcheck disable=SC1090,SC1091
    source ~/.sdkman/bin/sdkman-init.sh
fi
