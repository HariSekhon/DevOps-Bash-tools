#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-12-19 10:02:31 +0000 (Thu, 19 Dec 2019)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Generates an AWS IAM credentials report and waits for it to finish

Called from adjacent scripts as a dependency so that they can then pull specific information from the report

Requires iam:GenerateCredentialReport on resource: *


See Also:

    more AWS tools in the DevOps Python Tools repo and The Advanced Nagios Plugins Collection:

    - https://github.com/HariSekhon/DevOps-Python-tools
    - https://github.com/HariSekhon/Nagios-Plugins


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"


SECONDS=0
MAX_SECONDS=60

# you must run this to generate the report before you can get this info, seems to be ready a couple secs later
while true; do
    if aws iam generate-credential-report --output json |
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
