#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-11-24 12:40:18 +0000 (Wed, 24 Nov 2021)
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
. "$srcdir/lib/aws.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Reads a value from the command line and saves it to AWS Secrets Manager without echo'ing it on the screen

First argument is used as secret name
Second argument is used as secret string value if it doesn't start with option swtich double dashes -- and a letter
    - if this argument is a file, such as an SSH key, reads the file content and saves it as the secret value
    - if not given prompts for it with a non-echo'ing prompt (recommended for passwords)
Remaining args are passed directly to 'aws secretsmanager'

Examples:

    ${0##*/} myname

    ${0##*/} myname myvalue

    ${0##*/} myname myvalue --description 'test credential'

    # For accessing in Jenkins via https://plugins.jenkins.io/aws-secrets-manager-credentials-provider/
    ${0##*/} mysecretstring --tags 'Key=jenkins:credentials:type,Value=string'
    ${0##*/} mypass         --tags 'Key=jenkins:credentials:type,Value=usernamePassword'  'Key=jenkins:credentials:username,Value=hari'
    ${0##*/} mysshkey       --tags 'Key=jenkins:credentials:type,Value=sshUserPrivateKey' 'Key=jenkins:credentials:username,Value=hari'

$usage_aws_cli_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<name> [<secret> --description 'blah' <aws_options>]"

help_usage "$@"

min_args 1 "$@"

name="$1"
# perhaps somebody wants a secret value starting with a dash
if ! [[ "${2:-}" =~ ^--[[:alpha:]]+ ]]; then
    secret="${2:-}"
    shift || :
fi
shift || :

if [ -z "${secret:-}" ]; then
    echo "Secret not given as second arg"
    read_secret
fi

if [ -f "$secret" ]; then
    secret="$(cat "$secret")"
fi

aws secretsmanager create-secret --name "$name" --secret-string "$secret" "$@"
