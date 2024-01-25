#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-04-01 18:33:42 +0100 (Wed, 01 Apr 2020)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://buildkite.com/docs/apis/rest-api/agents

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/utils.sh"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_description="
Lists BuildKite Agents via the BuildKite API

Output format:

<agent_name>    <hostname>    <ip_address>    <started_date>    <user_agent>    <tags>

eg.

myhost.local-1  myhost.local    <ip_x.x.x.x>  2020-09-07T17:07:10.578Z    buildkite-agent/3.20.0.3264 (darwin; amd64) os=mac
fb3e859b5cb8-1  fb3e859b5cb8    <ip_x.x.x.x>  2020-09-07T17:05:18.562Z    buildkite-agent/3.23.0.x (linux; amd64) os=linux,distro=alpine
arbitrary_name  b03797c47520    <ip_x.x.x.x>  2020-09-07T17:05:38.062Z    buildkite-agent/3.23.0.x (linux; amd64) os=linux,distro=centos

The 2nd and 3rd agents are running in Docker hence the hostname field is nonsensical, but if you use the adjacent buildkite_agent.sh it'll set
the agent name to the same as the hostname for intuitive results and auto-add some tags for os and linux distro
"

# shellcheck disable=SC2034
usage_args="[<curl_options>]"

help_usage "$@"

"$srcdir/buildkite_api.sh" "organizations/{organization}/agents" "$@" |
jq -r '.[] | [.name, .hostname, .ip_address, .created_at, .user_agent, (.meta_data | join(",")) ] | @tsv'
