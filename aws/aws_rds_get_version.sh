#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2024-08-26 17:02:07 +0200 (Mon, 26 Aug 2024)
#
#  https///github.com/HariSekhon/DevOps-Bash-tools
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
Quickly retrieve the version of an RDS database matching an AWS instance name or IP address

This is important to fetch a match JDBC jar file using ../install/download_*_jdbc.sh script


When an IP address is given, since this is not available in AWS CLI output, has to iterate
through the list or RDS instance URL endpoints doing DNS lookups until it finds it. This is an O(n)
operation and can be expensive if you have a lot of instances, so you are recommended to supply the
RDS instance name instead if you know it. This IP resolution functionality was because teams sometimes
only gave me the IP address of a database when requesting JDBC setup to them
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<rds_name_or_ip>"

help_usage "$@"

min_args 1 "$@"

rds_instance="$1"

# $ip_regex defined in lib/utils.sh
# shellcheck disable=SC2154
if [[ "$rds_instance" =~ $ip_regex ]]; then
    ip="$rds_instance"
    rds_instance=""
    while read -r instance fqdn; do
        timestamp
        echo -n "Checking IP of instance '$instance' - $fqdn => " >&2
        # check if it's a CNAME and double resolve if so
        cname="$(dig +short "$fqdn" CNAME)"
        if [ -n "$cname" ]; then
            ip_result="$(dig +short "$cname" A)"
        else
            ip_result="$(dig +short "$fqdn" A)"
        fi
        echo "$ip_result" >&2
        if [ "$ip_result" = "$ip" ]; then
            timestamp "Found RDS instance with IP '$ip' to be '$instance'"
            rds_instance="$instance"
            break
        fi
    done < <(aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,Endpoint.Address]' --output text)
    if [ -z "$rds_instance" ]; then
        die "Failed to find RDS instance by IP in region '$(aws_region)' - perhaps IP is wrong or \$AWS_DEFAULT_REGION is not set correctly?"
    fi
fi

#aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier==\`$rds_instance\`].[DBInstanceIdentifier,Engine,EngineVersion]" --output text
version="$(aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier==\`$rds_instance\`].[EngineVersion]" --output text)"

if [ -z "$version" ]; then
    die "Failed to find RDS instance '$rds_instance' in region '$(aws_region)' - perhaps name is wrong or \$AWS_DEFAULT_REGION is not set correctly?"
fi

if [ "$(awk '{print NF}' <<< "$version")" -gt 1 ]; then
    die "WARNING: more than one version token returned: $version"
fi

echo "$version"
