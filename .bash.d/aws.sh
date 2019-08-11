#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2012-09-01 13:01:11 +0100
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                A W S  -  A m a z o n   W e b   S e r v i c e s
# ============================================================================ #

# JAVA_HOME needs to be set to use EC2 api tools
#[ -x /usr/bin/java ] && export JAVA_HOME=/usr  # errors but still works

# link_latest '/usr/local/ec2-api-tools-*'
export EC2_HOME=/usr/local/ec2-api-tools   # this should be a link to the unzipped ec2-api-tools-1.6.1.4/
add_PATH "$EC2_HOME/bin"

# ec2dre - ec2-describe-regions - list regions you have access to and put them here
# TODO: pull a more recent list and have aliases/functions auto-generated from that to export
aws_eu(){
    export EC2_URL=ec2.eu-west-1.amazonaws.com
}
aws_useast(){
    export EC2_URL=ec2.us-east-1.amazonaws.com
}
#aws_eu

# Storing creds in one place in Boto creds file, pull them straight from there
# export AWS_ACCESS_KEY
# export AWS_SECRET_KEY
eval "$(
for key in aws_access_key_id aws_secret_access_key; do
    awk -F= "/^[[:space:]]*$key/"'{gsub(/[[:space:]]+/, "", $0); gsub(/_id/, "", $1); gsub(/_secret_access/, "_secret", $1); print "export "toupper($1)"="$2}' "$HOME/.boto"
done
)"
