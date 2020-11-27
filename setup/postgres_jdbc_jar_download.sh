#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-27 14:21:49 +0000 (Fri, 27 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# Useful to quickly download the PostgreSQL JDBC jar

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

POSTGRESQL_JDBC_VERSION="${1:-42.2.18}"

if type -P wget; then
    wget -O "postgresql-$POSTGRESQL_JDBC_VERSION.jar" "https://jdbc.postgresql.org/download/postgresql-$POSTGRESQL_JDBC_VERSION.jar"
else
    curl --fail "https://jdbc.postgresql.org/download/postgresql-$POSTGRESQL_JDBC_VERSION.jar" > "postgresql-$POSTGRESQL_JDBC_VERSION.jar"
fi
