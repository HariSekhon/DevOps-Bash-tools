#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2025-03-17 20:04:16 +0800 (Mon, 17 Mar 2025)
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
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Sets the Macbook Pro microphone to use the internal mic as sometimes Apple AirPods mic sound muffled to others
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

num_args 0 "$@"

if ! is_mac; then
    die "Only supported on Mac"
fi

if ! type -P brew &>/dev/null; then
    "$srcdir/../install/install_homebrew.sh"
fi

if ! type SwitchAudioSource &>/dev/null; then
    brew install switchaudio-osx
fi

internal_mic="$(SwitchAudioSource -a | grep Microphone | grep -v -i -e iPhone -e AirPods || :)"

if [[ $(wc -l <<< "$internal_mic") -ge 2 ]]; then
    die "ERROR: more than one microphone returned:

$internal_mic
"
fi

if [ -z "$internal_mic" ]; then
    die "ERROR: failed to determine internal mic"
fi

#SwitchAudioSource -t input -s "MacBook Pro Microphone"
#timestamp "Switching to microphone: $internal_mic"
SwitchAudioSource -t input -s "$internal_mic"
