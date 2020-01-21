#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-21 17:20:46 +0000 (Tue, 21 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Lists AWS Config recorders, checking all resource types are supported (should be true) and includes global resources (should be true)
#
# eg.
#
# awsconfig  true  true

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

aws configservice describe-configuration-recorders |
jq -r '.ConfigurationRecorders[] | [.name, .recordingGroup.allSupported, .recordingGroup.includeGlobalResourceTypes] | @tsv' |
column -t
