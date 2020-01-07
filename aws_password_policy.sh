#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-01-07 11:57:18 +0000 (Tue, 07 Jan 2020)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Dumps password policy to key = value pairs for easy viewing / grepping
#
# adjacent script aws_harden_password_policy.sh calls this before and after changing
# the password policy to be hardened according to the CIS Foundations Benchmark recommendations

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

aws iam get-account-password-policy |
jq -r '.PasswordPolicy | to_entries | map(.key + " = " + (.value | tostring)) | .[]'
