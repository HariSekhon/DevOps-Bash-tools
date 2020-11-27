#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-24 11:54:52 +0000 (Tue, 24 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Useful to quickly get the MySQL connector jar eg. to upload to Kubernetes

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

MYSQL_VERSION="${1:-8.0.22}"

curl -sSL --fail "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-$MYSQL_VERSION.tar.gz" |
tar zxvf - -C . --strip 1 "mysql-connector-java-$MYSQL_VERSION/mysql-connector-java-$MYSQL_VERSION.jar"
