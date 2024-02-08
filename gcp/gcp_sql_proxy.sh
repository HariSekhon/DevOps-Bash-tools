#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-01 15:37:49 +0000 (Mon, 01 Feb 2021)
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
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

SOCKDIR=~/cloud_sql.socks

# shellcheck disable=SC2034,SC2154
usage_description="
Opens a Cloud SQL Proxy for all instances in given GCP Project(s) or all GCP Projects

Populates \$HOME/cloud_sql.socks/ directory with all your Cloud SQL instances sockets

Makes it quicker and easier to connect than slow 'gcloud sql connect' commands (which also requires a public IP address attached to your SQL instance)


Usage:

    ${0##*/}

    psql -h ~/cloud_sql.socks/<instance> ...

    mysql -S ~/cloud_sql.socks/<instance> ...



Auto-installs Google Cloud SQL Proxy if not found in \$PATH


Restart to pick up any new Cloud SQL instances

Useful to quick interactive DBA work

For production long-lived proxying, use dedicated Cloud SQL Proxy instances with service account credentials (avoid application default login expiry or restarts for picking up new instances)
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<projects>]"

help_usage "$@"

if [ $# -gt 0 ]; then
    projects="${*:-}"
else
    projects="$(gcloud projects list --format='get(project_id)')"
fi
not_blank "$projects" || die "ERROR: no project specified and GCloud SDK core.project property not set"

export PATH="$PATH:"~/bin

if ! type -P cloud_sql_proxy &>/dev/null; then
    "$srcdir/../install/install_cloud_sql_proxy.sh"
fi

mkdir -p -v "$SOCKDIR"

projects="${projects//[[:space:]]/,}"

# prompt for Application Default credentials if not already found
if ! gcloud auth application-default print-access-token &>/dev/null; then
    gcloud auth application-default login
fi

cmd=(cloud_sql_proxy -projects "$projects" -dir "$SOCKDIR")

echo "${cmd[*]}"
"${cmd[@]}"
