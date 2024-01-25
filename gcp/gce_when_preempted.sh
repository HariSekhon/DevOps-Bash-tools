#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-11-21 16:02:54 +0000 (Thu, 21 Nov 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    cat <<EOF
Waits and watches GCE Metadata API for the preemption trigger before continuing to execute its arguments

Alternative to shutdown scripts or if you want to set up an interactive CLI latch on preemption

https://cloud.google.com/compute/docs/shutdownscript

Usage:

 ${0##*/} "command1; command2; command 3"        All commands execute in a subshell

 ${0##*/}; command 1; command2; command 3        All commands execute in current shell
                                                                     (notice the semi-colon immediately after the script giving it no argument, merely using it as a latch mechanism)

 ${0##*/} command1; command2; command 3          First command executes in the subshell (it's an argument). Commands 2 & 3 execute in the current shell after this script

 ${0##*/} 'x=test; echo \$x'                      Variable is interpolated inside the single quotes at runtime after receiving Spot Termination notice


Inspired by whenup() / whendown() for hosts and whendone() for processes from interactive bash library .bash.d/* sourced as part of the .bashrc in this repo

For AWS there is a similar adjacent script aws_spot_when_terminated.sh

EOF
    exit 3
}

if [[ "${1:-}" =~ -.* ]]; then
    usage
fi

if ! curl -sS -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/" &>/dev/null; then
    echo "This script must be run from within a GCE instance as that is the only place the GCP GCE Metadata API is available"
    exit 2
fi

if output="$(curl -sS -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/preempted?wait_for_change=true")"; then
    if grep -q TRUE <<< "$output"; then
        "$@"
    else
        echo "not preempted, skipping commands"
        exit 1
    fi
else
    echo "FAILED to query GCE Metadata API, not running inside GCE?"
    exit 2
fi
