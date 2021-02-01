#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-01 15:37:49 +0000 (Mon, 01 Feb 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Opens a Cloud SQL Proxy for all instances in given or all GCP Projects

Populates \$HOME/cloud_sql.socks/ directory with all your Cloud SQL instances sockets to make it quicker and easy to connect than 'gcloud sql connect'


Auto-installs Google Cloud SQL Proxy if not found in \$PATH


Restart to pick up any new Cloud SQL instances. Useful for quick interactive work.

For production, use dedicated Cloud SQL Proxy instances with service account credentials (avoid application default login expiry or restarts for picking up new instances)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<projects>"

SOCKDIR=~/cloud_sql.socks

help_usage "$@"

if [ $# -gt 0 ]; then
    projects="${*:-}"
else
    projects="$(gcloud projects list --format='get(project_id)')"
fi

export PATH="$PATH:"~/bin

if ! type -P cloud_sql_proxy &>/dev/null; then
    "$srcdir/install_cloud_sql_proxy.sh"
fi

mkdir -p -v "$SOCKDIR"

projects="${projects//[[:space:]]/,}"

cmd=(cloud_sql_proxy -projects "$projects" -dir "$SOCKDIR")

echo "${cmd[*]}"
"${cmd[@]}"
