#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-19 01:55:24 +0000 (Tue, 19 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

cat "$@" |
sed '
    s/[>=].*$//;
    s/^python-//;
    s/-*python$//;
    s/-/_/g;
    s/beautifulsoup4/bs4/;
    s/traceback2/traceback/;
    s/MySQL/MySQLdb/;
    s/PyYAML/yaml/;
    s/GitPython/git/;
    s/\[.*\]//;
' |
tr '[:upper:]' '[:lower:]' |
sed '
    s/mysqldb/MySQLdb/;
    s/krbv/krbV/;
'
