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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/kubernetes.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Uses SSH to dump logs to local text files for servers given as arguments for uploading to vendor support cases

Collects:

/var/log/messages
/var/log/dmesg


Dumps logs to files of this name format:

log.YYYY-MM-DD-HHSS.<server>.<log>.txt


For each server that is not prefixed by root@, uses sudo in ssh to copy the log file to the user's home directory first
to work around root file permissions issues and chown it to the login user


Requires SSH client to be installed and configured to preferably passwordless ssh key access


To select a different SSH key - for example because you are iterating AWS EC2 servers, just add that SSH key to your
ssh-agent

Start an SSH agent if you haven't already

    eval \"\$(ssh-agent -s\)\"

Then add the key - replace 'ec2-key.pem' with whatever your key is called:

    ssh-add ~/.ssh/ec2-key.pem

Have a look that it's added correctly

    ssh-add -l

Then run this script as usual
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<server1> [<server2> <server3>]"

help_usage "$@"

min_args 1 "$@"

for server in "$@"; do
    echo
    tstamp="$(date '+%F_%H%M')"
    #for log in messages secure dmesg; do
    for log in messages dmesg; do
        log_file="log.$tstamp.$server.$log.txt"
        # ignore && && || it works
        # shellcheck disable=SC2015
        timestamp "Dumping server '$server' log: $log" &&
        if ! [[ "$server" =~ ^root@ ]]; then
            # want client side expansion
            # shellcheck disable=SC2029
            ssh "$server" "sudo cp -v /var/log/$log ~/$log_file && sudo chown -v \$USER ~/$log_file" &&
            scp "$server":"./$log_file" .
        else
            scp "$server":"/var/log/$log" "$log_file"
        fi &&
        timestamp "Dumped server '$server' log to file: $log_file" ||
        warn "Failed to get '$server' log: $log"
        # XXX: because race condition - spot instances can go away during execution
        # and we still want to collect the rest of the servers
    done
done
echo
timestamp "Log dumps completed"
