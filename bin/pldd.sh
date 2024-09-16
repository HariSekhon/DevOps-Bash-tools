#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: $$
#
#  Author: Hari Sekhon
#  Date: 2024-09-16 02:32:28 +0200 (Mon, 16 Sep 2024)
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
On Linux parses the /proc/<pid>/maps to list all dyanmic so libraries that a program is using

The runtime equivalent of the classic Linux ldd command

Because sometimes the system pldd command gives results like this:

    pldd: cannot attach to process 32781: Operation not permitted
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<pid>"

help_usage "$@"

num_args 1 "$@"

pid="$1"

if ! is_linux; then
    usage "ERROR: this script only runs on Linux"
fi

max_pid="$(cat /proc/sys/kernel/pid_max)"

if ! is_int "$max_pid"; then
	die "ERROR: failed to determine max pid of the system, got: $max_pid"
fi

if ! is_int "$pid" ||
   ! [ "$pid" -ge 1 ] ||
   ! [ "$pid" -le "$max_pid" ]; then
	die "Error: PID '$pid' is not in the valid range of 1 to $max_pid"
fi

maps_file="/proc/$pid/maps"

if [ ! -f "$maps_file" ]; then
    echo "Could not find /proc/$pid/maps"
    exit 1
fi

while IFS= read -r line; do
    # last field contains the file path
    lib_path="$(awk '{print $NF}' <<< "$line")"

	# if the path contains in '.so' its a shared library
    if [[ "$lib_path" =~ \.so$ ]] ||
       [[ "$lib_path" =~ \.so\. ]]; then
        realpath=$(readlink -f "$lib_path" 2>/dev/null)
        if [ -n "$realpath" ]; then
            echo "$realpath"
        else
            echo "$lib_path"
        fi
    fi
done < "$maps_file" |
sort -u
