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

# shellcheck disable=SC2034,SC2154
usage_description="
Uses SSH to dump common command outputs from remote servers to a local tarball. Useful for vendor support cases

Copies adjacent dump_stats.sh script to the remote server, executes it, and collects the resulting tarball back to the local machine

The collected tarball will in this name format:

<server>.stats-bundle.YYYY-MM-DD-HHSS.tar.gz


Lsof output is not included by default as it is very voluminous, see dump_stats.sh for details and to enable it


Requires SSH client to be installed and configured to preferably passwordless ssh key access
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<server1> [<server2> <server3>]"

help_usage "$@"

min_args 1 "$@"

for server in "$@"; do
    scp "$srcdir/dump_stats.sh" "$server":
    # doesn't work - might have to be allowed in sshd_config which is not portable by default
    #ssh -o SendEnv=DEBUG "$server" "
    # want client side expansion
    # shellcheck disable=SC2029,SC2015
    ssh "$server" "
        export DEBUG=\"${DEBUG:-}\"
        export LSOF=\"${LSOF:-}\"
        chmod +x dump_stats.sh &&
        ./dump_stats.sh
    " &&
    latest_tarball="$(ssh "$server" "ls -tr stats-bundle-*.tar.gz | tail -n 1")" &&
    timestamp "Collecting tarball '$latest_tarball'" &&
    scp "$server":"$latest_tarball" "$server.$latest_tarball" &&
    timestamp "Collected tarball" &&
    timestamp "Removing tarball on server to save space" &&
    ssh "$server" "rm -fv -- ./$latest_tarball" ||
    warn "Failed to collect tarball from server '$server'"
    # XXX: because race condition - spot instances can go away during execution
    # and we still want to collect the rest of the servers
done

timestamp "Stats dumps completed"
