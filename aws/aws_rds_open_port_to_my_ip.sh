#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-06-27 13:17:51 +0200 (Thu, 27 Jun 2024)
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
Adds a security group to an RDS DB instance to open its native database SQL port to your public IP address

- determines your public IP address
- determines the RDS DB instance's port (usually 3306 for MySQL or 5432 for PostgreSQL)
- creates a security group containing your username in its name
- adds a rule to the security group to permit the DB port from your public IP
- adds the security group to the RDS DB instance


$usage_aws_cli_jq_required
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<instance_name>"

help_usage "$@"

num_args 1 "$@"

db_instance="$1"

user="${USER:-whoami}"

if is_blank "$user"; then
    die "Failed to determine username to label the new security group with"
fi

timestamp "Determining your public IP"
public_ip="$(curl -sS https://checkip.amazonaws.com || curl -sS ifconfig.co/json | jq -r '.ip')"

# $ip_regex is imported from utils.sh which is imported from aws.sh above
# shellcheck disable=SC2154
if ! [[ "$public_ip" =~ $ip_regex ]]; then
    die "Failed to determine your IP address"
fi

timestamp "Determined your public IP to be '$public_ip'"

timestamp "Determining the port of the database instance '$db_instance'"
port="$(aws rds describe-db-instances --db-instance-identifier "$db_instance" --query 'DBInstances[0].Endpoint.Port' --output text)"
timestamp "Determined DB port to be '$port'"

security_group="$user-rds-home-access"

timestamp "Determining VPC Id for DB instance '$db_instance'"
vpc_id="$(aws rds describe-db-instances --db-instance-identifier "$db_instance" \
                                     --query 'DBInstances[0].DBSubnetGroup.VpcId' --output text)"
timestamp "Determined VPC Id to be '$vpc_id'"

if aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=vpc-043c8640ca46649b4" \
                  "Name=group-name,Values=hari-rds-home-access" \
        --query 'SecurityGroups[0].GroupId' \
        --output text >/dev/null; then
    timestamp "Security group '$security_group' already exists, skipping creation"
else
    timestamp "Creating security group '$security_group'"
    aws ec2 create-security-group --group-name "$security_group" \
                                  --description "Security group for RDS access for $user home IP" \
                                  --vpc-id "$vpc_id"
fi

#security_group_id="$(aws ec2 describe-security-groups --group-names "$security_group" --query 'SecurityGroups[0].GroupId' --output text)"
security_group_id="$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$vpc_id" \
        "Name=group-name,Values=hari-rds-home-access" \
        --query 'SecurityGroups[0].GroupId' \
        --output text)"

security_group_rules="$(aws ec2 describe-security-groups --group-ids "$security_group_id" --query 'SecurityGroups[0].IpPermissions' --output json)"

cidr="$public_ip/32"
protocol="tcp"

security_rule_exists=$(jq -r \
    --arg protocol "$protocol" \
    --arg port "$port" \
    --arg cidr "$cidr" '
        .[] |
        select(.IpProtocol == $protocol and
               .FromPort   == ($port | tonumber) and
               .ToPort == ($port | tonumber) and
               .IpRanges[]?.CidrIp == $cidr) |
        length > 0
' <<< "$security_group_rules")

if [ "$security_rule_exists" = "true" ]; then
  timestamp "Security rule already exists in security group '$security_group', skipping adding it"
else
    timestamp "Adding rule to security group '$security_group' opening port $port to your IP '$public_ip'"
    aws ec2 authorize-security-group-ingress \
                --group-id "$security_group_id" \
                --protocol tcp \
                --port "$port" \
                --cidr "$cidr"
fi

timestamp "Adding security group '$security_group' to RDS instance '$db_instance'"
aws rds modify-db-instance --db-instance-identifier "$db_instance" --vpc-security-group-ids "$security_group_id" --apply-immediately >/dev/null

timestamp "RDS DB instance '$db_instance' port '$port' is now open to your IP '$public_ip'"
