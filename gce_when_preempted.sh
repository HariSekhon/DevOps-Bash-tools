#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-11-21 16:02:54 +0000 (Thu, 21 Nov 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

usage(){
    echo "
Waits and watches GCE Metadata API for the preemption trigger before continuing to execute it's arguments

Alternative to shutdown scripts if you want to interactively set up a CLI trigger on pre-emption

https://cloud.google.com/compute/docs/shutdownscript

${0##*/} <commands>
"
    exit 3
}

if [[ "${1:-}" =~ -.* ]]; then
    usage
fi

output="$(curl -s -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/preempted?wait_for_change=true")"
# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
    if grep -q TRUE <<< "$output"; then
        eval "$@"
    else
        echo "not preempted, skipping commands"
        exit 1
    fi
else
    echo "FAILED to query GCE Metadata API, not running inside GCE?"
    exit 2
fi
