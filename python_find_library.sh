#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-09-27 17:54:37 +0100 (Fri, 27 Sep 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Shows the path to Python libraries given as arguments
#
# There is a better version of this in the adjacent DevOps Python Tools repo called find_python_library_path.py
#
# Doesn't work for 'sys' module due to lack of __file__ support - you must use full Python version above which works around that

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

python="${PYTHON:-python}"

for arg; do
    "$python" -c "from __future__ import print_function; import $arg; print($arg.__file__)"
done
