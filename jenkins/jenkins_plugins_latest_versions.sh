#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: kubernetes
#
#  Author: Hari Sekhon
#  Date: 2024-01-31 02:32:56 +0000 (Wed, 31 Jan 2024)
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

# shellcheck disable=SC2034,SC2154
usage_description="
Finds the latest versions of Jenkins plugins given by args by querying:

    https://updates.jenkins.io/current/update-center.actual.json

Used by update_plugin_versions.sh script in https://github.com/HariSekhon/Kubernetes-configs/tree/master/jenkins/base
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<plugin>"

help_usage "$@"

any_opt_usage "$@"

min_args 1 "$@"

url="https://updates.jenkins.io/current/update-center.actual.json"

log "* downloading json"
json="$(curl -sSfL "$url" || die "failed to fetch json from '$url'")"

log "* checking not blank"
# extremely poor performance for large 3M json download
#if is_blank "$json"; then
if [ -z "$json" ]; then
    die "json returned from url '$url' is blank!"
fi


log "* parsing json"
#version="$(jq -r ".plugins[] | select(.name == \"$plugin\") | .version" <<< "$json")"
plugin_versions="$(jq -r '.plugins[] | .name + ":" + .version' <<< "$json")"

exitcode=0

log "* printing plugin:version for each found plugin"
for plugin in "$@"; do
    if ! grep "^$plugin:" <<< "$plugin_versions"; then
        warning "plugin '$plugin' not found! Have you provided the right plugin slug?"
        exitcode=1
    fi
done

#echo "$version"

exit $exitcode
