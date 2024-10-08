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
Dumps common command outputs to text files in a local tarball

Useful to collect support information for vendor support cases

Scp'd by ssh_dump_stats.sh to collect from remote servers


Creates a tarball in this name format:

stats-bundle.YYYY-MM-DD-HHSS.tar.gz


If this script is not run as root then prefixes sudo to every command to ensure that it succeeds


Export LSOF=true to dump the lsof output which is otherwise skipped by default because on a production VM it resulted in 599M of output which aside from taking 30 seconds was ballooning the even compressed tarball to 47MB instead of 108KB


If NO_REMOVE_STATS_DIR environment variable is set to any value then does not remove the intermediate stats-bundle.YYYY-MM-DD-HHSS directory
"

if [ $# -gt 0 ]; then
    echo "$usage_description"
    exit 3
fi

tstamp="$(date '+%F_%H%M')"

stats_bundle_dir="stats-bundle-$tstamp"

mkdir -p -v "$stats_bundle_dir"

cd "$stats_bundle_dir"

sudo=""
if [ "$EUID" -ne 0 ]; then
    sudo=sudo
fi

mac=false
if uname -s | grep Darwin; then
    mac=true
fi

timestamp(){
    printf "%s\n" "$(date '+%F %T')  $*" >&2
}

dump(){
    local name="$1"
    shift
    local cmd=("$name")
    if [ $# -gt 0 ]; then
        cmd=("$@")
    fi
    cmd_name="${cmd[0]}"
    if ! type -P "$cmd_name" &>/dev/null; then
        timestamp "Command '$cmd_name' not found, skipping..."
        return
    fi
    log_file="$name-output.$tstamp.txt"
    # ignore && && || it works
    # shellcheck disable=SC2015
    timestamp "Collecting $name output" >&2
    $sudo "${cmd[@]}" > "$log_file"
    timestamp  "Collected $name output to file: $log_file"
    echo >&2
}

# ============================================================================ #
#                    Commands that work on both Linux and Mac
# ============================================================================ #

dump_common(){

    timestamp "Dumping common command outputs"
    echo >&2
    # -g for GB only works on Mac
    #dump df df -g
    dump df df -h
    dump dmesg
    # very expensive - takes 30 seconds and results in a 599MB output file on a production informatica secure agent server VM
    if [ "${LSOF:-}" = true ]; then
        dump lsof lsof -n -O
    fi
    dump netstat netstat -an
    dump ps_ef ps -ef
    dump uname uname -a
    dump uptime

}

# ============================================================================ #
#                         Commands that only work on Mac
# ============================================================================ #

dump_mac(){

    timestamp "Dumping Mac specific command outputs"
    echo >&2
    dump diskutil_list diskutil list
    dump iostat iostat -c 5
    dump memory_pressure
    dump ps_auxf ps aux
    dump top top -l 1
    dump top_mpstat top -l 1 -stats pid,command,cpu,th,pstate,time,cpu -ncols 16
    dump vmstat
}

# ============================================================================ #
#                        Commands that only work on Linux
# ============================================================================ #

dump_linux(){

    timestamp "Dumping Linux specific command outputs"
    echo >&2
    dump free free -g
    dump iostat iostat -x 1 5
    dump lsblk
    dump mpstat mpstat -P ALL 1 5
    dump ps_auxf ps auxf
    dump sar_5 sar -u 1 5
    dump sar_all sar -A
    dump top top -H -b -n 1
    dump vmstat vmstat 1 5
}

# ============================================================================ #

dump_common

if [ "$mac" = true ]; then
    dump_mac
else # assume Linux as the default case
    dump_linux
fi

timestamp "Finished collection"
echo >&2

tarball="$stats_bundle_dir.tar.gz"

timestamp "Creating compressed tarball '$tarball' for easier collection and space savings"

cd ..

tar czvf "$tarball" "$stats_bundle_dir"
echo

if [ -z "${NO_REMOVE_STATS_DIR:-}" ]; then
    timestamp "Removing directory: $stats_bundle_dir"
    rm -fr -- "$stats_bundle_dir"
    echo >&2
fi

timestamp "Collect tarball at: $PWD/$tarball"
