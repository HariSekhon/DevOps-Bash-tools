#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-26 14:38:31 +0200 (Mon, 26 Aug 2024)
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
#srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage_description="
Dumps common command outputs to local text files

Use to collect for support information

Used by ssh_dump_stats.sh

Collects:

df -g

free -g

sar -A  (if sar is found installed in \$PATH)


Dumps logs to files in this name format:

<name>-output.YYYY-MM-DD-HHSS.txt
"

if [ $# -gt 0 ]; then
    echo "$usage_description"
    exit 3
fi

tstamp="$(date '+%F_%H%M')"

support_bundle_dir=~/"support-bundle-$tstamp"

mkdir -p -v "$support_bundle_dir"

cd "$support_bundle_dir"

sudo=""
if [ "$EUID" -ne 0 ]; then
    sudo=sudo
fi

dump_stat(){
    local name="$1"
    local cmd=("$@")
    log_file="$name-output.$tstamp.txt"
    # ignore && && || it works
    # shellcheck disable=SC2015
    echo "Collecting $name output" >&2
    $sudo "${cmd[@]}" > "$log_file"
    timestamp "Collected $name output to file: $log_file" ||
    warn "Failed to get $name output"
}

dump_stat "df" df -g

dump_stat free free -g

if type -P sar; then
    dump_stat sar sar -A
fi
