#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-19 10:02:31 +0000 (Thu, 19 Dec 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Generates an AWS IAM credentials report and waits for it to finish
#
# Called from adjacent scripts as a dependency
#
# See more AWS tools in the DevOps Python Tools repo and The Advanced Nagios Plugins Collection:
#
# - https://github.com/harisekhon/devops-python-tools
# - https://github.com/harisekhon/nagios-plugins

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

SECONDS=0
MAX_SECONDS=60

# you must run this to generate the report before you can get this info, seems to be ready a couple secs later
while true; do
    if aws iam generate-credential-report |
    jq -r .State |
    tee /dev/stderr |
    grep -q COMPLETE; then
        break
    fi
    if [ $SECONDS -gt $MAX_SECONDS ]; then
        echo "AWS IAM Credentials report failed to return complete within $MAX_SECONDS"
        exit 1
    fi
done
