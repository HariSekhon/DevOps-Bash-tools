#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  shellcheck disable=SC2178,SC2001,SC2128,SC2179
#
#  Author: Hari Sekhon
#  Date: 2024-07-23 20:43:59 +0300 (Tue, 23 Jul 2024)
#  Ported from Perl version
#  Original Date: 2013-02-11 11:50:00 +0000 (Mon, 11 Feb 2013)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Prints all the command line classpaths of Java processes

Optionally filter Java processes by a giving a regex
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<command_process_regex_ere_format>]"

help_usage "$@"

max_args 1 "$@"

# ERE format for [[
command_regex="${1:-.*}"

if ! is_regex "$command_regex"; then
    echo "Invalid command regex supplied: $command_regex"
    exit 1
fi

# use GNU ps on Mac to maintain compatibility
# doesn't work in subshells
#if is_mac; then
#    ps(){
#        gps "$@"
#    }
#    export -f ps
#fi

is_jps_output(){
	# JPS output format
    [[ "$1" =~ ^([[:digit:]]+)[[:space:]]+([[:alnum:]]*)$ ]]
}

replace_classpath_with_token(){
    sed 's/[[:space:]]-\(cp\|classpath\)[[:space:]=]\+[^ ]\+\([[:space:]]\|$\)/ <CLASSPATHS> /' <<< "$1"
}

show_cli_classpath(){
    local cmd="$1"
    [[ "$cmd" =~ java ]] || return
    args="${cmd#*java }"
    cmd="$(replace_classpath_with_token "$cmd")"
	echo
    echo "command:  $cmd"
    echo
    count=0
	# XXX: will break upon directories in classpath containing a space, but this should be rare on unix systems
    classpaths="$(grep -Eo -- '[[:space:]]-(cp|classpath)[[:space:]]*([^[:space:]]+)')"
	classpaths="${classpaths## }"
	classpaths="${classpaths##-cp}"
	classpaths="${classpaths##-classpath}"
	classpaths="${classpaths##=}"
	IFS=':' read -r -a classpaths <<< "$classpaths"
	for classpath in "${classpaths[@]}"; do
		[ -z "$classpath" ] && continue
		echo "classpath:  $classpath"
		count=$((count + 1))
	done
    [ $count -gt 0 ] && echo
    echo "$count classpath(s) found"
    echo
}

show_jinfo_classpath(){
    local cmd="$1"
    if is_jps_output "$cmd"; then
        #pid="${cmd%% *}" # first token is pid
        pid="${BASH_REMATCH[1]}"
        # skip Jps itself which may be lingering in the process list from our call before this function
        [ "${BASH_REMATCH[2]:-}" = Jps ] && return
		if [ -z "${BASH_REMATCH[2]:-}" ]; then
            cmd+=" <embedded JVM no classname from JPS output>"
        fi
        echo "JPS:     $cmd"
        echo "command: $(ps -f -p "$pid" | tail -n +2 | sed 's/^[[:space:]]*//')"
        echo
    else
        if ! [[ "$cmd" =~ java ]]; then
            # shellcheck disable=SC2028
            echo "skipping $cmd since it doesn't match regex 'java'"
            return
        fi
        cmd="$(replace_classpath_with_token "$cmd")"
        echo
        echo "command:  $cmd"
        if [[ "$cmd" =~ ^[[:space:]]*[[:alnum:]]+[[:space:]]+[[:digit:]]+[[:space:]]+ ]]; then
            echo "ps -ef input detected"
        elif [[ "$cmd" =~ ^[[:space:]]*[[:digit:]]+[[:space:]]+[[:alnum:]]+[[:space:]]+ ]]; then
            echo "ps aux input detected"
        else
            echo "Invalid input to show_jinfo_classpath, expecting '<pid> <classname>' or '<pid> <user> <cmd>' or 'ps -ef' or 'ps aux' input"
            return
        fi
        pid="$(grep -Eo '^[[:digit:]]+' <<< "$cmd")"
    fi
    output="$(jinfo "$pid")"
    found_classpath=0
    while IFS= read -r line; do
        # breaks on this content:
        #
        #   /Users/hari/Library/Application Support/JetBrains/IdeaIC2023.3/plugins/sonarlint-intellij/sloop/lib/error_prone_annotations-2.18.0.jar
        #
        #if [[ "$line" =~ error ]]; then
        #    echo "jinfo error detected attaching to process id $pid"
        #    echo "$line"
        #    return
        #fi
        if [[ "$line" =~ ^java.class.path[[:space:]]*=[[:space:]]* ]]; then
            line="${line#*=}"
            line="${line# }"
            count=0
            IFS=':' read -r -a classpaths <<< "$line"
            for classpath in "${classpaths[@]}"; do
                [ -z "$classpath" ] && continue
                echo "classpath:  $classpath"
                count=$((count + 1))
            done
            [ $count -gt 0 ] && echo
            echo "$count classpath(s) found"
            echo
            found_classpath=1
            break
        fi
    done <<< "$output"
    if [ $found_classpath -eq 0 ]; then
        echo "Failed to find java classpath in output from jinfo!"
    fi
    hr
}

if ! process_list="$(jps 2>/dev/null)"; then
	echo "WARNING: jps failed, perhaps not in \$PATH? (\$PATH = $PATH)" >&2
	echo "WARNING: Falling back to ps command" >&2
	process_list="$(ps -e -o pid,user,command)"
fi

while IFS= read -r line; do
    log "input: $line"
	if is_jps_output "$line"; then
        if [ -n "$command_regex" ]; then
            if [[ "$line" =~ $command_regex ]]; then
                show_jinfo_classpath "$line"
            fi
        else
            show_jinfo_classpath "$line"
        fi
    elif [[ "$line" =~ java.*$command_regex ]]; then
        #show_jinfo_classpath "$line"
        show_cli_classpath "$line"
    fi
done <<< "$process_list"
