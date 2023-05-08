#!/usr/bin/env bash
# shellcheck disable=SC2230
#
#  Author: Hari Sekhon
#  Date: 2019-09-24
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying LICENSE file
#
#  https://www.linkedin.com/in/HariSekhon
#

# Updated gitignore based on existing gitignore.io API in the file
#
# gitignore.io

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

header="Created by https://www.gitignore.io/api/"

set +eo pipefail
url="$(grep "$header" .gitignore)"
set -eo pipefail

if [ -z "$url" ]; then
    echo
    echo "No gitignore.io API url found in .gitignore"
    echo
    echo "You need to add the gitignore.io content to .gitignore initially to choose your selections, this script merely runs an update based on the API url recorded in the comments"
    exit 1
fi

url="$(head -n1 <<< "${url/*https:/https:}")"

sed_regex="${header//\//\\/}"
sed -i.bak "/$sed_regex/,\$d" .gitignore

curl -sS "$url" |
sed 's/[[:space:]]*$//' |
sed -n "/$sed_regex/,\$p" >> .gitignore
