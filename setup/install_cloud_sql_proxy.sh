#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2021-02-01 15:01:24 +0000 (Mon, 01 Feb 2021)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://cloud.google.com/sql/docs/postgres/sql-proxy

# Installs Google Cloud SQL Proxy to $HOME/bin
#
# only supports 64-bit Linux / Mac (who uses 32-bit any more?)

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

if type -P cloud_sql_proxy 2>/dev/null; then
    echo "Google Cloud SQL Proxy is already installed, skipping install..."
    exit 0
fi

os="$(uname -s | tr '[:upper:]' '[:lower:]')"

url="https://dl.google.com/cloudsql/cloud_sql_proxy.$os.amd64"

cd /tmp

echo "Downloading Google Cloud SQL Proxy"
wget -qO cloud_sql_proxy "$url"

echo "setting executable"
chmod +x cloud_sql_proxy

echo "moving to ~/bin"
mv cloud_sql_proxy ~/bin

echo "Done. Don't forget to add $HOME/bin to \$PATH"
