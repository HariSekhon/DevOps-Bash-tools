#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2026-09-15 15:57:13 +0800 (Tue, 15 Sep 2026)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn
#  and optionally send me feedback
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
Creates a portable atomic lock using a given directory

Useful for a script to prevent two instances from running at the same time to avoid either data corruption
or API rate limits

Written for my Spotify backups so I can schedule them safely while preventing concurrent runspthat could trip the
Spotify API rate limits

If you're on Linux you should use flock if available for its enhanced kernel integration to clean up locks

The lock directory must NOT be the current or any existing directory, otherwise this script will wait indefinitely
and should be unique to your script or collection of related scripts that you want to share a mutually exclusive lock between

Parent directory to the lockdir must exist, such as /tmp, in order to catch typos from creating new directory trees

There are two ways this script can be used as:

1. a wrapper script in which commands are passed as arguments and executed inside this script
2. a locking line in a script where the calling script is then responsible for removing the pid file and locking
   directory afterwards, recommended using a trap like so:

    trap 'rm -f \"\$pidfile\"; rmdir \"\$lockdir\"' EXIT

Warning: a 'kill -9' of the script may leave behind the lock dir and require manual cleanup
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<lockdir> [<commands>]"

help_usage "$@"

min_args 2 "$@"

lockdir="$1"
pidfile="$lockdir/pid"
shift || :

if [ -f "$lockdir" ]; then
    usage "Lockdir given is an existing file, must specify a directory, not a file: $lockdir"
fi

timestamp "Acquiring directory lock on: $lockdir"
while ! mkdir "$lockdir" 2>/dev/null; do
    # the second arg is an excepted file, here we ignore the "pid" file if this is the only contents as it is caused by this or related script invocation and not a general directory that is really populated
    if is_directory_populated "$lockdir" "pid"; then
        warn "Directory already exists with content, possible incorrect usage giving pre-existing data directory?"
    fi
    timestamp "Lock directory already exists, waiting for it to be released and not exist..."
    sleep 1
done

pid="$$"
#timestamp "Adding pid to $pidfile"
echo "$pid" >> "$pidfile"
timestamp "Lock acquired by pid: $$"
trap_cmd "rm -f '$pidfile'; rmdir '$lockdir'"

"$@"
